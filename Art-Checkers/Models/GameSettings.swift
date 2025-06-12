import SwiftUI

struct GameSettings: Codable, Equatable {
    var playerColor: PieceColor
    var timerMode: TimerMode
    var timePerMove: Double
    var boardStyle: Int
}

enum TimerMode: String, Codable, Equatable {
    case noLimit
    case timePerMove
}

