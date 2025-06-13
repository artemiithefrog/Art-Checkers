//
//  RoomCell.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct RoomCell: View {
    let peer: String
    let isConnecting: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(peer)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(isConnecting ? "Connecting..." : "Tap to connect")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
            
            if isConnecting {
                ProgressView()
                    .tint(.gray)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onTapGesture(perform: onConnect)
        .disabled(isConnecting)
    }
}
