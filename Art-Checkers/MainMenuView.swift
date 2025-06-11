import SwiftUI

struct MainMenuView: View {
    @State private var showNewGameSheet = false
    @State private var showSettingsSheet = false
    @EnvironmentObject var gameRoom: GameRoom
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    @State private var showGameView = false
    @State private var selectedPosition: Position?
    @State private var draggedPiece: Piece?
    @State private var dragOffset: CGSize = .zero
    @StateObject private var game = CheckersGame()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.98, blue: 0.98),
                        Color(red: 0.95, green: 0.95, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    HStack {
                        Spacer()
                        Button {
                            showSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 0) {
                                ForEach(0..<4) { row in
                                    HStack(spacing: 0) {
                                        ForEach(0..<4) { col in
                                            Rectangle()
                                                .fill((row + col) % 2 == 0 ? 
                                                    Color(red: 0.2, green: 0.2, blue: 0.2) : 
                                                    Color(red: 0.9, green: 0.9, blue: 0.9))
                                                .frame(width: 25, height: 25)
                                        }
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Text("Art Checkers")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    }
                    .padding(.bottom, 60)

                    VStack(spacing: 20) {
                        MenuButton(
                            title: "New Game",
                            icon: "plus.circle.fill",
                            color: Color(red: 0.2, green: 0.6, blue: 0.9)
                        ) {
                            showNewGameSheet = true
                        }
                        
                        MenuButton(
                            title: "Connect to Room",
                            icon: "link.circle.fill",
                            color: Color(red: 0.3, green: 0.8, blue: 0.6)
                        ) {
                            gameRoom.startBrowsing()
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showNewGameSheet) {
                NewGameView(showGame: $showGame, gameSettings: $gameSettings)
                    .environmentObject(gameRoom)
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .onChange(of: gameRoom.connectedPeers.isEmpty) { isEmpty in
                if !isEmpty {
                    showGameView = true
                }
            }
            .onChange(of: gameRoom.currentSettings) { newSettings in
                if let settings = newSettings {
                    gameSettings = settings
                }
            }
            .navigationDestination(isPresented: $showGameView) {
                CheckersBoardView(
                    game: game,
                    selectedPosition: $selectedPosition,
                    draggedPiece: $draggedPiece,
                    dragOffset: $dragOffset,
                    settings: GameSettings(
                        playerColor: gameRoom.isHost ? .white : .black,
                        timerMode: gameRoom.currentSettings?.timerMode ?? .noLimit,
                        timePerMove: gameRoom.currentSettings?.timePerMove ?? 0,
                        boardStyle: UserDefaultsManager.shared.getSelectedBoardStyle()
                    ),
                    showGame: $showGameView,
                    gameRoom: gameRoom
                )
                .onAppear {
                    game.gameRoom = gameRoom
                    if !gameRoom.isHost {
                        game.currentPlayer = .black
                    }
                }
                .navigationBarBackButtonHidden()
            }
        }
    }
}

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

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(showGame: .constant(false), gameSettings: .constant(nil))
    }
} 
