//
//  SettingsView.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedBoardStyle = UserDefaultsManager.shared.getSelectedBoardStyle()
    @State private var showBoardStylePicker = false
    
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
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)

                VStack(spacing: 24) {
                    Button(action: {
                        showBoardStylePicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Board Style")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                Text(boardStyles[selectedBoardStyle].name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .sheet(isPresented: $showBoardStylePicker) {
            BoardStylePickerView(selectedStyle: $selectedBoardStyle)
        }
    }
}
