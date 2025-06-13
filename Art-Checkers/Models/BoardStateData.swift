//
//  BoardStateData.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 13.06.2025.
//

import Foundation

struct BoardStateData: Codable {
    let boardState: [[String]]
    let capturedWhite: Int
    let capturedBlack: Int
}
