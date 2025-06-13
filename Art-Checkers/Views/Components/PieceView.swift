//
//  PieceView.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct PieceView: View {
    let piece: Piece
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            piece.color == .white ? Color.white : Color.black.opacity(0.8),
                            piece.color == .white ? Color.white.opacity(0.8) : Color.black
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(radius: 2)
                .overlay(
                    Circle()
                        .stroke(
                            piece.color == .white ? Color.black.opacity(0.3) : Color.white.opacity(0.3),
                            lineWidth: 1
                        )
                        .padding(size * 0.15)
                )
            
            if piece.isKing {
                Image(systemName: "crown.fill")
                    .foregroundColor(piece.color == .white ? .black : .white)
                    .font(.system(size: size * 0.4))
            }
        }
    }
}
