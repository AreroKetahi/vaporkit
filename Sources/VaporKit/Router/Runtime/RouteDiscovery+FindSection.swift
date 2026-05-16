//
//  RouteDiscovery+FindSection.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 15/05/2026
//

internal func _findRouteRecordSections() -> [UnsafeRawBufferPointer] {
#if canImport(MachO)
    return unsafe _findSectionInLoadedImages(segment: "__DATA_CONST", section: "__swift5_vpkt")
#elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
    return unsafe _findELFRouteRecordSections()
#elseif os(Windows)
    return _findCOFFSections(section: ".sw5vpkt")
#else
    return []
#endif
}

// MARK: - MachO

#if objectFormat(MachO)

import MachO

private func _getSectionData(
    header: UnsafePointer<mach_header_64>,
    segment: StaticString,
    section: StaticString
) -> UnsafeRawBufferPointer? {
    var size: UInt = 0
    
    guard let start = unsafe getsectiondata(
        header,
        segment.utf8Start,
        section.utf8Start,
        &size
    ), size > 0 else {
        return nil
    }
    
    return unsafe UnsafeRawBufferPointer(
        start: UnsafeRawPointer(start),
        count: Int(size)
    )
}

func _findSectionInLoadedImages(
    segment: StaticString,
    section: StaticString
) -> [UnsafeRawBufferPointer] {
    var results: [UnsafeRawBufferPointer] = unsafe []
    let count = _dyld_image_count()
    for index in 0..<count {
        guard let header = unsafe _dyld_get_image_header(index) else {
            continue
        }
        
        let rawHeader = unsafe UnsafeRawPointer(header)
        guard unsafe header.pointee.magic == MH_MAGIC_64 else {
            continue
        }
        
        let header64 = unsafe rawHeader.assumingMemoryBound(
            to: mach_header_64.self
        )
        if let buffer = unsafe _getSectionData(
            header: header64,
            segment: segment,
            section: section
        ) {
            unsafe results.append(buffer)
        }
    }
    
    return unsafe results
}
#endif

// MARK: - ELF

#if os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)

private struct _ELFSectionBound: Sendable, ~Copyable {
    private var storage: CChar = 0
    
    static func ..<(
        lhs: inout Self,
        rhs: inout Self
    ) -> Range<UnsafeRawPointer> {
        unsafe withUnsafeMutablePointer(to: &lhs) { lhs in
            unsafe withUnsafeMutablePointer(to: &rhs) { rhs in
                unsafe UnsafeRawPointer(lhs) ..< UnsafeRawPointer(rhs)
            }
        }
    }
}

@_silgen_name("__start_swift5_vpkt")
private nonisolated(unsafe) var _swift5VPKTSectionStart: _ELFSectionBound

@_silgen_name("__stop_swift5_vpkt")
private nonisolated(unsafe) var _swift5VPKTSectionEnd: _ELFSectionBound

private func _findELFRouteRecordSections() -> [UnsafeRawBufferPointer] {
    let range = unsafe _swift5VPKTSectionStart ..< _swift5VPKTSectionEnd
    guard range.count > 0 else {
        return []
    }
    
    return [
        unsafe UnsafeRawBufferPointer(
            start: range.lowerBound,
            count: range.count
        )
    ]
}

#endif

// MARK: - COFF

#if os(Windows)

import WinSDK

extension HMODULE {
    private final class _AllState {
        var snapshot: HANDLE?
        var moduleEntry = MODULEENTRY32W()
        
        deinit {
            if let snapshot {
                CloseHandle(snapshot)
            }
        }
    }
    
    fileprivate static var _allLoadedModules: some Sequence<HMODULE> {
        sequence(state: _AllState()) { state in
            if let snapshot = state.snapshot {
                if Module32NextW(snapshot, &state.moduleEntry) {
                    return state.moduleEntry.hModule
                }
            } else {
                guard let snapshot = CreateToolhelp32Snapshot(
                    DWORD(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32),
                    0
                ) else {
                    return nil
                }
                
                state.snapshot = snapshot
                state.moduleEntry.dwSize = DWORD(
                    MemoryLayout.stride(ofValue: state.moduleEntry)
                )
                
                if Module32FirstW(snapshot, &state.moduleEntry) {
                    return state.moduleEntry.hModule
                }
            }
            
            return nil
        }
    }
    
    fileprivate func _withNTHeader<R>(
        _ body: (UnsafePointer<IMAGE_NT_HEADERS>?) throws -> R
    ) rethrows -> R {
        try withMemoryRebound(to: IMAGE_DOS_HEADER.self, capacity: 1) { dosHeader in
            guard
                dosHeader.pointee.e_magic == IMAGE_DOS_SIGNATURE,
                let eLFANew = Int(exactly: dosHeader.pointee.e_lfanew),
                eLFANew > 0
            else {
                return try body(nil)
            }
            
            let ntHeader = (UnsafeRawPointer(dosHeader) + eLFANew)
                .assumingMemoryBound(to: IMAGE_NT_HEADERS.self)
            guard ntHeader.pointee.Signature == IMAGE_NT_SIGNATURE else {
                return try body(nil)
            }
            
            return try body(ntHeader)
        }
    }
}

private func _firstSectionHeader(
    for ntHeader: UnsafePointer<IMAGE_NT_HEADERS>
) -> UnsafePointer<IMAGE_SECTION_HEADER> {
    let optionalHeaderOffset =
    MemoryLayout<DWORD>.stride +
    MemoryLayout<IMAGE_FILE_HEADER>.stride
    let sectionHeaderOffset =
    optionalHeaderOffset +
    Int(ntHeader.pointee.FileHeader.SizeOfOptionalHeader)
    
    return (UnsafeRawPointer(ntHeader) + sectionHeaderOffset)
        .assumingMemoryBound(to: IMAGE_SECTION_HEADER.self)
}

private func _sectionNameMatches(
    _ sectionHeader: IMAGE_SECTION_HEADER,
    _ expectedName: String
) -> Bool {
    let expected = Array(expectedName.utf8)
    guard expected.count <= IMAGE_SIZEOF_SHORT_NAME else {
        return false
    }
    
    return withUnsafeBytes(of: sectionHeader.Name) { rawName in
        for index in 0..<IMAGE_SIZEOF_SHORT_NAME {
            let actualByte = rawName[index]
            let expectedByte = index < expected.count ? expected[index] : 0
            guard actualByte == expectedByte else {
                return false
            }
        }
        
        return true
    }
}

private func _stripCOFFSwiftPadding(
    from buffer: UnsafeRawBufferPointer
) -> UnsafeRawBufferPointer {
    guard buffer.count > 2 * MemoryLayout<UInt>.stride else {
        return buffer
    }
    
    let firstValue = buffer.baseAddress!.loadUnaligned(as: UInt.self)
    let lastValue = (buffer.baseAddress! + buffer.count - MemoryLayout<UInt>.stride)
        .loadUnaligned(as: UInt.self)
    guard firstValue == 0, lastValue == 0 else {
        return buffer
    }
    
    return UnsafeRawBufferPointer(
        rebasing: buffer
            .dropFirst(MemoryLayout<UInt>.stride)
            .dropLast(MemoryLayout<UInt>.stride)
    )
}

private func _findCOFFSections(
    section: String
) -> [UnsafeRawBufferPointer] {
    HMODULE._allLoadedModules.compactMap { module in
        module._withNTHeader { ntHeader -> UnsafeRawBufferPointer? in
            guard let ntHeader else {
                return nil
            }
            
            let sectionHeaders = UnsafeBufferPointer(
                start: _firstSectionHeader(for: ntHeader),
                count: Int(clamping: ntHeader.pointee.FileHeader.NumberOfSections)
            )
            
            for sectionHeader in sectionHeaders {
                guard _sectionNameMatches(sectionHeader, section) else {
                    continue
                }
                
                guard
                    let virtualAddress = Int(exactly: sectionHeader.VirtualAddress),
                    virtualAddress > 0
                else {
                    return nil
                }
                
                let virtualSize = Int(clamping: sectionHeader.Misc.VirtualSize)
                let rawSize = Int(clamping: sectionHeader.SizeOfRawData)
                let size = min(max(0, virtualSize), max(0, rawSize))
                guard size > 0 else {
                    return nil
                }
                
                let buffer = UnsafeRawBufferPointer(
                    start: UnsafeRawPointer(module) + virtualAddress,
                    count: size
                )
                return _stripCOFFSwiftPadding(from: buffer)
            }
            
            return nil
        }
    }
}

#endif
