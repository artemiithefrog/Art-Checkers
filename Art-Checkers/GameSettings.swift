import SwiftUI

struct GameSettings: Codable {
    var playerColor: PieceColor
    var timerMode: TimerMode
    var timePerMove: Double
    var boardStyle: Int
}

enum TimerMode: String, Codable {
    case noLimit
    case timePerMove
}

