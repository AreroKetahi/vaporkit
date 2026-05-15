import SwiftSyntaxMacros

#if canImport(VaporKitMacros)
import VaporKitMacros

let testMacros: [String: Macro.Type] = [
    "Router": RouterMacro.self,
    "ValidatableModel": ValidatableMacro.self,
    "Bypass": BypassMacro.self,
    
    "Get": EmptyMacro.self,
    "Post": EmptyMacro.self,
    "On": EmptyMacro.self,
    "Put": EmptyMacro.self,
    "Delete": EmptyMacro.self,
    "WebSocket": EmptyMacro.self,
    "OnText": EmptyExpressionMacro.self,
    "OnBinary": EmptyExpressionMacro.self,
    "OnClose": EmptyExpressionMacro.self,
    "RouteHandler": EmptyMacro.self,
    "Middleware": EmptyMacro.self,
    "Register": EmptyMacro.self,
    "ForwardParameters": EmptyMacro.self,
    "DisableParameterCheck": EmptyMacro.self,
    "AutoRegisterable": EmptyMacro.self,
    "Constraint": EmptyMacro.self,
    "Attribute": EmptyMacro.self,
    "Relationship": EmptyMacro.self,
]
#endif
