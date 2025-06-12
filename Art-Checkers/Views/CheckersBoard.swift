//
//  CheckersBoard.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct CheckersBoard: View {
    let board: [[String]]
    let squareSize: CGFloat
    let isHost: Bool
    let boardStyle: Int
    
    private let boardStyles = [
        (name: "Classic Brown", colors: (Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.9, green: 0.7, blue: 0.5))),
        (name: "Modern Gray", colors: (Color(red: 0.3, green: 0.3, blue: 0.3), Color(red: 0.8, green: 0.8, blue: 0.8))),
        (name: "Elegant Blue", colors: (Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.6, green: 0.8, blue: 1.0))),
        (name: "Vintage Green", colors: (Color(red: 0.2, green: 0.6, blue: 0.3), Color(red: 0.6, green: 0.9, blue: 0.5))),
        (name: "Royal Purple", colors: (Color(red: 0.4, green: 0.2, blue: 0.6), Color(red: 0.7, green: 0.5, blue: 0.9))),
        (name: "Sunset Orange", colors: (Color(red: 0.8, green: 0.4, blue: 0.2), Color(red: 1.0, green: 0.7, blue: 0.5))),
        (name: "Cherry Red", colors: (Color(red: 0.7, green: 0.2, blue: 0.2), Color(red: 0.9, green: 0.5, blue: 0.5))),
        (name: "Mint Green", colors: (Color(red: 0.2, green: 0.7, blue: 0.5), Color(red: 0.5, green: 0.9, blue: 0.7)))
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<8) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8) { col in
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? boardStyles[boardStyle].colors.0 : boardStyles[boardStyle].colors.1)
                                .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
            
            ForEach(0..<8) { row in
                ForEach(0..<8) { col in
                    if board[row][col] != "." {
                        let piece = board[row][col]
                        let displayRow = isHost ? row : 7 - row
                        let displayCol = isHost ? col : 7 - col
                        let position = CGPoint(
                            x: CGFloat(displayCol) * squareSize + squareSize / 2,
                            y: CGFloat(displayRow) * squareSize + squareSize / 2
                        )
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        piece.hasPrefix("W") ? Color.white : Color.black.opacity(0.8),
                                        piece.hasPrefix("W") ? Color.white.opacity(0.8) : Color.black
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: squareSize * 0.8, height: squareSize * 0.8)
                            .shadow(radius: 2)
                            .overlay(
                                Circle()
                                    .stroke(
                                        piece.hasPrefix("W") ? Color.black.opacity(0.3) : Color.white.opacity(0.3),
                                        lineWidth: 1
                                    )
                                    .padding(squareSize * 0.15)
                            )
                            .overlay(
                                Group {
                                    if piece.hasSuffix("K") {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(piece.hasPrefix("W") ? .black : .white)
                                            .font(.system(size: squareSize * 0.4))
                                    }
                                }
                            )
                            .position(position)
                    }
                }
            }
        }
    }
}
