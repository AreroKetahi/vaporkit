//
//  RouteDiscovery.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 15/05/2026
//

public enum _RouteDiscovery {
    public static let kind: UInt32 = 0x766B_7274 // vkrt -> VaporKit RouTe
    public static let version: UInt32 = 1
    
    public static func _discover() -> [_RouteDescriptor] {
        unsafe _findRouteRecordSections().flatMap { buffer in
            unsafe buffer.withMemoryRebound(to: _RouteRegisterRecord.self) { recordBuffers in
                unsafe recordBuffers.compactMap(__loadDescriptor)
            }
        }
    }
    
    private static func __loadDescriptor(
        _ record: _RouteRegisterRecord
    ) -> _RouteDescriptor? {
        guard unsafe record.kind == kind else { return nil }
        guard unsafe record.version == version else { return nil }
        guard let accessor = unsafe record.accessor else { return nil }
        
        return unsafe withUnsafeTemporaryAllocation(of: _RouteDescriptor.self, capacity: 1) { buffer in
            let initialized = unsafe withUnsafePointer(to: _RouteDescriptor.self) { type in
                unsafe accessor(buffer.baseAddress!, UnsafeRawPointer(type), nil, 0)
            }
            
            guard initialized else { return nil }
            return unsafe buffer.baseAddress!.move()
        }
    }
}
