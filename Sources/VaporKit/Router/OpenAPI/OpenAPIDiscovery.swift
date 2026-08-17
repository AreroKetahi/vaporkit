//
//  OpenAPIDiscovery.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

public enum _OpenAPIDiscovery {
    public static let kind: UInt32 = 0x766B_6F61 // vkoa -> VaporKit OpenAPI
    public static let version: UInt32 = 1

    public static func discover() -> [_OpenAPIRouterDescriptor] {
        unsafe _findOpenAPIRecordSections().flatMap { buffer in
            unsafe buffer.withMemoryRebound(to: _OpenAPIRegisterRecord.self) { records in
                unsafe records.compactMap(loadDescriptor)
            }
        }
    }

    private static func loadDescriptor(
        _ record: _OpenAPIRegisterRecord
    ) -> _OpenAPIRouterDescriptor? {
        guard unsafe record.kind == kind, unsafe record.version == version else {
            return nil
        }

        #if swift(>=6.4)
        return withUnsafeTemporaryAllocation(of: _OpenAPIRouterDescriptor.self, capacity: 1) { buffer in
            let initialized = withUnsafePointer(to: _OpenAPIRouterDescriptor.self) { type in
                unsafe record.accessor(buffer.baseAddress!, UnsafeRawPointer(type), nil, 0)
            }
            return initialized ? unsafe buffer.baseAddress!.move() : nil
        }
        #else
        return unsafe withUnsafeTemporaryAllocation(of: _OpenAPIRouterDescriptor.self, capacity: 1) { buffer in
            let initialized = unsafe withUnsafePointer(to: _OpenAPIRouterDescriptor.self) { type in
                unsafe record.accessor(buffer.baseAddress!, UnsafeRawPointer(type), nil, 0)
            }
            return initialized ? unsafe buffer.baseAddress!.move() : nil
        }
        #endif
    }
}
