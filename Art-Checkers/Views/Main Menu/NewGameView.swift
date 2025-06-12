//
//  NewGameView.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct NewGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var timePerMove: Double = 0
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    @EnvironmentObject var gameRoom: GameRoom
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("New Game")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.gray)
                Text("Customize your game")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding(.top, 40)
            .padding(.bottom, 40)

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "timer")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time per move")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Text("\(Int(timePerMove)) seconds")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    
                    Slider(value: $timePerMove, in: 0...300, step: 30)
                        .tint(.gray)
                        .padding(.leading, 30)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
            .padding(.horizontal)
            
            Spacer()

            Button(action: {
                let settings = GameSettings(
                    playerColor: .white,
                    timerMode: timePerMove > 0 ? .timePerMove : .noLimit,
                    timePerMove: timePerMove,
                    boardStyle: UserDefaultsManager.shared.getSelectedBoardStyle()
                )
                
                gameSettings = settings
                gameRoom.startHosting(settings: settings)
                showGame = true
                dismiss()
            }) {
                HStack {
                    Text("Start Game")
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
}
