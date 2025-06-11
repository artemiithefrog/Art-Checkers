import SwiftUI

struct MainMenuView: View {
    @State private var showNewGameSheet = false
    @EnvironmentObject var gameRoom: GameRoom
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    @State private var showCounterView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Art Checkers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                Button {
                    showNewGameSheet = true
                } label: {
                    Text("New Game")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button {
                    gameRoom.startBrowsing()
                } label: {
                    Text("Connect to room")
                        .font(.title2)
                        .foregroundColor(Color.white)
                        .frame(width: 250, height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding()
            .sheet(isPresented: $showNewGameSheet) {
                NewGameView(showGame: $showGame, gameSettings: $gameSettings)
                    .environmentObject(gameRoom)
            }
            .onChange(of: gameRoom.connectedPeers.isEmpty) { isEmpty in
                if !isEmpty {
                    showCounterView = true
                }
            }
            .sheet(isPresented: $showCounterView) {
                CounterView()
                    .environmentObject(gameRoom)
            }
        }
    }
}

struct NewGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedBoardStyle = UserDefaultsManager.shared.getSelectedBoardStyle()
    @State private var timePerMove: Double = 0
    @State private var showBoardStylePicker = false
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    @EnvironmentObject var gameRoom: GameRoom
    
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
                    boardStyle: selectedBoardStyle
                )
                
                gameSettings = settings
                gameRoom.startHosting()
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
        .sheet(isPresented: $showBoardStylePicker) {
            BoardStylePickerView(selectedStyle: $selectedBoardStyle)
        }
    }
}

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

struct CounterView: View {
    @EnvironmentObject var gameRoom: GameRoom
    @State private var previousBoardState: [[String]] = Array(repeating: Array(repeating: ".", count: 8), count: 8)
    @State private var piecePositions: [String: CGPoint] = [:]
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    
                    Text("Current Player: \(gameRoom.currentPlayer)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Spacer()
                
                GeometryReader { geometry in
                    let squareSize = min(geometry.size.width, geometry.size.height) / 8
                    
                    CheckersBoard(board: gameRoom.boardState, squareSize: squareSize)
                        .onChange(of: gameRoom.boardState) { newState in
                            for row in 0..<8 {
                                for col in 0..<8 {
                                    let piece = newState[row][col]
                                    if piece != "." {
                                        let position = CGPoint(
                                            x: CGFloat(col) * squareSize + squareSize / 2,
                                            y: CGFloat(row) * squareSize + squareSize / 2
                                        )
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            piecePositions[piece] = position
                                        }
                                    }
                                }
                            }
                        }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding()
                
                Spacer()
            }
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(showGame: .constant(false), gameSettings: .constant(nil))
    }
} 
