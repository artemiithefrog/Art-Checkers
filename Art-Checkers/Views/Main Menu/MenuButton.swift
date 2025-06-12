//
//  MenuButton.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}
