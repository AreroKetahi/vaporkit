//
//  RouterMacro.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct VaporkitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RouterMacro.self,
        ValidatableMacro.self,
        BypassMacro.self,
        EmptyMacro.self,
        EmptyExpressionMacro.self,
    ]
}
