//
//  OpenAPISchema+StandardTypes.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

import Foundation

extension String: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .string)
}

extension Bool: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .boolean)
}

extension Int: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .integer, format: .int64)
}

extension Int32: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .integer, format: .int32)
}

extension Int64: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .integer, format: .int64)
}

extension Float: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .number, format: .float)
}

extension Double: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .number, format: .double)
}

extension UUID: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .string, format: .uuid)
}

extension Date: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .string, format: .dateTime)
}

extension Never: OpenAPISchema {
    public static let openAPISchema = OpenAPISchemaMetadata(type: .null)
}

extension Array: OpenAPISchema where Element: OpenAPISchema {
    public static var openAPISchema: OpenAPISchemaMetadata {
        OpenAPISchemaMetadata(type: .array, items: Element.openAPISchema)
    }
}

extension Dictionary: OpenAPISchema where Key == String, Value: OpenAPISchema {
    public static var openAPISchema: OpenAPISchemaMetadata {
        OpenAPISchemaMetadata(
            type: .object,
            additionalProperties: Value.openAPISchema
        )
    }
}

extension Optional: OpenAPISchema where Wrapped: OpenAPISchema {
    public static var openAPISchema: OpenAPISchemaMetadata {
        var schema = Wrapped.openAPISchema
        if var types = schema.types {
            if !types.contains(.null) { types.append(.null) }
            schema.types = types
            return schema
        }
        return OpenAPISchemaMetadata(
            anyOf: [schema, OpenAPISchemaMetadata(type: .null)]
        )
    }
}
