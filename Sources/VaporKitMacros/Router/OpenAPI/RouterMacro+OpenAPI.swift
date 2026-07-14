//
//  RouterMacro+OpenAPI.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
    static func openAPIRecordDeclarations(
        for declaration: any DeclGroupSyntax,
        typeName: String,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let accessorName = context.makeUniqueName("VaporKitOpenAPI_accessor")
        let recordName = context.makeUniqueName("VaporKitOpenAPI_record")
        let routerPath = routerPrefix(from: node) ?? ""
        let handlers = openAPIHandlerExpressions(
            in: declaration,
            routerIdentifier: typeName,
            context: context
        ).joined(separator: ",\n")
        let children = openAPIRegisteredRouterIdentifiers(in: declaration)
            .map { #""\#($0)""# }
            .joined(separator: ", ")

        return [
            """
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private nonisolated let \(accessorName): VaporKit._OpenAPIRegisterAccessor = { outValue, type, _, _ in
                guard unsafe type.load(as: Any.Type.self) == VaporKit._OpenAPIRouterDescriptor.self else {
                    return false
                }

                unsafe outValue.initializeMemory(
                    as: VaporKit._OpenAPIRouterDescriptor.self,
                    to: VaporKit._OpenAPIRouterDescriptor(
                        identifier: \(literal: typeName),
                        path: \(literal: routerPath),
                        handlers: [\(raw: handlers)],
                        registeredRouters: [\(raw: children)]
                    )
                )
                return true
            }
            """,
            """
            #if objectFormat(MachO)
            @section("__DATA_CONST,__swift5_vkoa")
            #elseif objectFormat(ELF)
            @section("swift5_vkoa")
            #elseif objectFormat(COFF)
            @section(".sw5vkoa")
            #endif
            @used
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private let \(recordName): VaporKit._OpenAPIRegisterRecord = (
                0x766B_6F61,
                1,
                { unsafe \(accessorName)($0, $1, $2, $3) },
                0,
                0
            )
            """
        ]
    }

}
