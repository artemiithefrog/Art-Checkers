import SwiftUI

struct MainMenuView: View {
    @State private var showNewGameSheet = false
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Art Checkers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                Button(action: {
                    showNewGameSheet = true
                }) {
                    Text("Create New Room")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // TODO: Show rooms list
                }) {
                    Text("Join Room")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // TODO: Join random room
                }) {
                    Text("Join Random Room")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
            .padding()
            .sheet(isPresented: $showNewGameSheet) {
                NewGameView(showGame: $showGame, gameSettings: $gameSettings)
            }
        }
    }
}

struct NewGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedColor: PieceColor = .white
    @State private var timerMode: TimerMode = .noLimit
    @State private var timePerMove: Double = 30
    @State private var showBoardPicker = false
    @State private var selectedBoardStyle = UserDefaultsManager.shared.getSelectedBoardStyle()
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Settings")) {
                    Picker("Your Color", selection: $selectedColor) {
                        Text("White").tag(PieceColor.white)
                        Text("Black").tag(PieceColor.black)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Timer", selection: $timerMode) {
                        Text("No Limit").tag(TimerMode.noLimit)
                        Text("Time Per Move").tag(TimerMode.timePerMove)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if timerMode == .timePerMove {
                        VStack {
                            Text("\(Int(timePerMove)) seconds")
                            Slider(value: $timePerMove, in: 5...60, step: 5)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showBoardPicker = true
                    }) {
                        HStack {
                            Text("Board Style")
                            Spacer()
                            Text("Select")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        gameSettings = GameSettings(
                            playerColor: selectedColor,
                            timerMode: timerMode,
                            timePerMove: timePerMove,
                            boardStyle: selectedBoardStyle
                        )
                        showGame = true
                        dismiss()
                    }) {
                        Text("Start Game")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("New Game")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showBoardPicker) {
                BoardStylePickerView(selectedStyle: $selectedBoardStyle)
            }
        }
    }
}

struct BoardStylePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedStyle: Int
    let boardStyles: [(name: String, light: Color, dark: Color)] = [
        ("Classic Brown", Color.brown.opacity(0.3), Color.brown.opacity(0.7)),
        ("Forest Green", Color.green.opacity(0.3), Color.green.opacity(0.7)),
        ("Ocean Blue", Color.blue.opacity(0.3), Color.blue.opacity(0.7)),
        ("Elegant Gray", Color.gray.opacity(0.3), Color.gray.opacity(0.7)),
        ("Royal Purple", Color.purple.opacity(0.3), Color.purple.opacity(0.7)),
        ("Sunset Orange", Color.orange.opacity(0.3), Color.orange.opacity(0.7)),
        ("Cherry Red", Color.red.opacity(0.3), Color.red.opacity(0.7)),
        ("Mint Green", Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3), Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.7))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<boardStyles.count, id: \.self) { index in
                        BoardStylePreview(
                            name: boardStyles[index].name,
                            lightColor: boardStyles[index].light,
                            darkColor: boardStyles[index].dark,
                            isSelected: selectedStyle == index
                        )
                        .onTapGesture {
                            selectedStyle = index
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Board Style")
            .navigationBarItems(trailing: Button("Done") {
                UserDefaultsManager.shared.saveSelectedBoardStyle(selectedStyle)
                dismiss()
            })
        }
    }
}

struct BoardStylePreview: View {
    let name: String
    let lightColor: Color
    let darkColor: Color
    let isSelected: Bool
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ForEach(0..<8) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8) { col in
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? lightColor : darkColor)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            
            Text(name)
                .font(.caption)
                .padding(.top, 8)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
}

enum TimerMode {
    case noLimit
    case timePerMove
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(showGame: .constant(false), gameSettings: .constant(nil))
    }
} 