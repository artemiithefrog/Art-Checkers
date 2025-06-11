//
//  ContentView.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 10.06.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = CheckersGame()
    @State private var selectedPosition: Position?
    @State private var draggedPiece: Piece?
    @State private var dragOffset: CGSize = .zero
    @State private var showGame = false
    @State private var gameSettings: GameSettings?
    @StateObject private var gameRoom = GameRoom()
    
    var body: some View {
        if showGame, let settings = gameSettings {
            CheckersBoardView(
                game: game,
                selectedPosition: $selectedPosition,
                draggedPiece: $draggedPiece,
                dragOffset: $dragOffset,
                settings: settings,
                showGame: $showGame
            )
        } else {
            MainMenuView(showGame: $showGame, gameSettings: $gameSettings)
                .environmentObject(gameRoom)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
