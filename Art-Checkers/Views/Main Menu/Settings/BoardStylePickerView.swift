//
//  BoardStylePickerView.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct BoardStylePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedStyle: Int
    
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
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Choose Board Style")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gray)
                        Text("Select your preferred board design")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(0..<boardStyles.count, id: \.self) { index in
                            BoardStyleCard(
                                style: boardStyles[index],
                                isSelected: selectedStyle == index,
                                action: {
                                    selectedStyle = index
                                    UserDefaultsManager.shared.saveSelectedBoardStyle(index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarItems(
                trailing: Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gray)
                }
            )
        }
    }
}
