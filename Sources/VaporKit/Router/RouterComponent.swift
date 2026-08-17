//
//  RouterComponent.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/08/2026
//

enum _RouterPathComponent {
    case literal(String)
    case decodable(named: String, as: any Decodable.Type)
    case losslessStringConvertible(named: String, as: any LosslessStringConvertible.Type)
    case label(String)
}
