//
//  Piece.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import Foundation

enum PieceColor: String, Codable, Equatable {
    case white
    case black
}

enum PieceType: String, Codable {
    case normal
    case king
}

struct Piece: Identifiable, Codable {
    let id = UUID()
    var color: PieceColor
    var type: PieceType
    var position: Position
    var isKing: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, color, type, position, isKing
    }
}

struct Position: Hashable, Codable {
    var row: Int
    var col: Int
}
