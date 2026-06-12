//
//  Router+Helper.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 12/06/2026
//

@propertyWrapper
public struct Path<Value> where Value: LosslessStringConvertible {
    public let wrappedValue: Value
    
    public init(wrappedValue: Value, _ name: StaticString) {
        self.wrappedValue = wrappedValue
    }
}
