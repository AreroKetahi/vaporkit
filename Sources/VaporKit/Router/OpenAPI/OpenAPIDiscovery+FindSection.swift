//
//  OpenAPIDiscovery+FindSection.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

internal func _findOpenAPIRecordSections() -> [UnsafeRawBufferPointer] {
#if canImport(MachO)
    return unsafe _findSectionInLoadedImages(segment: "__DATA_CONST", section: "__swift5_vkoa")
#elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
    return unsafe _findELFOpenAPIRecordSections()
#elseif os(Windows)
    return _findCOFFSections(section: ".sw5vkoa")
#else
    return []
#endif
}

#if os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
private struct _ELFOpenAPISectionBound: Sendable, ~Copyable {
    private var storage: CChar = 0

    static func ..<(lhs: inout Self, rhs: inout Self) -> Range<UnsafeRawPointer> {
        unsafe withUnsafeMutablePointer(to: &lhs) { lhs in
            unsafe withUnsafeMutablePointer(to: &rhs) { rhs in
                unsafe UnsafeRawPointer(lhs) ..< UnsafeRawPointer(rhs)
            }
        }
    }
}

private func _emptyELFOpenAPIRegisterAccessor(
    _ outValue: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ hint: UnsafeRawPointer?,
    _ reserved: UInt
) -> CBool { false }

@section("swift5_vkoa")
@used
private let _emptyELFOpenAPIRegisterRecord: _OpenAPIRegisterRecord = (
    kind: 0,
    version: 0,
    accessor: unsafe _emptyELFOpenAPIRegisterAccessor,
    context: 0,
    reserved: 0
)

@_silgen_name("__start_swift5_vkoa")
private nonisolated(unsafe) var _swift5VKOASectionStart: _ELFOpenAPISectionBound

@_silgen_name("__stop_swift5_vkoa")
private nonisolated(unsafe) var _swift5VKOASectionEnd: _ELFOpenAPISectionBound

private func _findELFOpenAPIRecordSections() -> [UnsafeRawBufferPointer] {
    let range = unsafe _swift5VKOASectionStart ..< _swift5VKOASectionEnd
    guard unsafe range.count > 0 else { return unsafe [] }
    return unsafe [UnsafeRawBufferPointer(start: range.lowerBound, count: range.count)]
}
#endif
