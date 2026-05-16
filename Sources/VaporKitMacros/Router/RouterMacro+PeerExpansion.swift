import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let declaration = declaration.asProtocol((any DeclGroupSyntax).self),
            hasAttribute(named: autoRegisterableAttributeName, in: declaration.attributes),
            let typeName = nominalTypeName(of: declaration)
        else {
            return []
        }

        let accessorName = context.makeUniqueName("VaporKitAutoRegister_accessor")
        let recordName = context.makeUniqueName("VaporKitAutoRegister_record")
        let descriptorID = "\(typeName)"

        return [
            """
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private nonisolated let \(accessorName): VaporKit._RouteRegisterAccessor = { outValue, type, _, _ in
                guard unsafe type.load(as: Any.Type.self) == VaporKit._RouteDescriptor.self else {
                    return false
                }

                unsafe outValue.initializeMemory(
                    as: VaporKit._RouteDescriptor.self,
                    to: VaporKit._RouteDescriptor(
                        id: \(literal: descriptorID),
                        routerName: \(literal: typeName),
                        makeCollection: {
                            \(raw: typeName)()
                        }
                    )
                )

                return true
            }
            """,
            """
            #if objectFormat(MachO)
            @section("__DATA_CONST,__swift5_vpkt")
            #elseif objectFormat(ELF)
            @section("swift5_vpkt")
            #elseif objectFormat(COFF)
            @section(".sw5vpkt")
            #endif
            @used
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private let \(recordName): VaporKit._RouteRegisterRecord = (
                0x766B_7274,
                1,
                { unsafe \(accessorName)($0, $1, $2, $3) },
                0,
                0
            )
            """
        ]
    }
}
