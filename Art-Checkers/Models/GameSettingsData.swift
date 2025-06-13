//
//  GameSettingsData.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 13.06.2025.
//

import Foundation

struct GameSettingsData: Codable {
    let playerColor: String
    let timerMode: String
    let timePerMove: Int
    let initialWhiteTime: Int
    let initialBlackTime: Int
}

