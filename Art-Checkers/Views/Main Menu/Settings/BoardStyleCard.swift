//
//  BoardStyleCard.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct BoardStyleCard: View {
    let style: (name: String, colors: (Color, Color))
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(style.colors.0)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.gray : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 0) {
                        ForEach(0..<4) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<4) { col in
                                    Rectangle()
                                        .fill((row + col) % 2 == 0 ? style.colors.0 : style.colors.1)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                    }
                    .padding(12)
                }

                HStack {
                    Text(style.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    } else {
                        Color.clear
                            .frame(width: 20, height: 20)
                    }
                }
                .frame(height: 24)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
