//
//  EmptyMacro.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EmptyMacro {}

extension EmptyMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

extension EmptyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
