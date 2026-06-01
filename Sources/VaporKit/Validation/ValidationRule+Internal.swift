//
//  ValidationRule+Internal.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 31/05/2026
//

extension ValidationRule {
    static func _member(_ name: String) -> Self {
        .init(kind: .member(name))
    }
    
    static func _call(_ name: String, arguments: [Argument]) -> Self {
        .init(kind: .call(name: name, arguments: arguments))
    }
    
    static func _renderRangeExpression<T: Comparable>(_ bounds: some RangeExpression<T>) -> String {
        let opaqueBounds = bounds as Any
        
        if let range = opaqueBounds as? ClosedRange<T> {
            return "\(String(describing: range.lowerBound))...\(String(describing: range.upperBound))"
        }
        
        if let range = opaqueBounds as? Range<T> {
            return "\(String(describing: range.lowerBound))..<\(String(describing: range.upperBound))"
        }
        
        if let range = opaqueBounds as? PartialRangeFrom<T> {
            return "\(String(describing: range.lowerBound))..."
        }
        
        if let range = opaqueBounds as? PartialRangeThrough<T> {
            return "...\(String(describing: range.upperBound))"
        }
        
        if let range = opaqueBounds as? PartialRangeUpTo<T> {
            return "..<\(String(describing: range.upperBound))"
        }
        
        return String(describing: bounds)
    }
}
