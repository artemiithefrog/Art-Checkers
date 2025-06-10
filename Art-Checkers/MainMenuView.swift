import SwiftUI

struct MainMenuView: View {
    @State private var showNewGameSheet = false
    @State private var showAvailableRooms = false
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
                    showAvailableRooms = true
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
            .sheet(isPresented: $showAvailableRooms) {
                AvailableRoomsView(showGame: $showGame, gameSettings: $gameSettings)
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
    @StateObject private var gameRoom = GameRoom()
    
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
                print("🎮 NewGameView: Creating new game room")
                print("🎮 NewGameView: Selected board style: \(boardStyles[selectedBoardStyle].name)")
                print("🎮 NewGameView: Time per move: \(Int(timePerMove)) seconds")
                
                let settings = GameSettings(
                    playerColor: .white,
                    timerMode: timePerMove > 0 ? .timePerMove : .noLimit,
                    timePerMove: timePerMove,
                    boardStyle: selectedBoardStyle
                )
                
                print("🎮 NewGameView: Starting game room with settings:")
                print("  - Player Color: \(settings.playerColor)")
                print("  - Timer Mode: \(settings.timerMode)")
                print("  - Time Per Move: \(settings.timePerMove)")
                print("  - Board Style: \(settings.boardStyle)")
                
                gameRoom.startHosting(settings: settings)
                gameSettings = settings
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
            
            if !gameRoom.statusMessage.isEmpty {
                Text(gameRoom.statusMessage)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
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
                                    print("🎨 BoardStylePickerView: Selected board style: \(boardStyles[index].name)")
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
                    print("🎨 BoardStylePickerView: Done selecting board style")
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

struct AvailableRoomsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    @StateObject private var gameRoom = GameRoom()
    @State private var isSearching = false
    @State private var searchStartTime = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Available Rooms")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.gray)
                    Text("Select a room to join")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding(.top, 40)
                .padding(.bottom, 40)
                
                if isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Searching for rooms...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        Text("Search time: \(Int(Date().timeIntervalSince(searchStartTime)))s")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else if gameRoom.connectedPeers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No rooms available")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        Button(action: {
                            startSearch()
                        }) {
                            Text("Search Again")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(gameRoom.connectedPeers, id: \.self) { peer in
                            Button(action: {
                                if let settings = gameRoom.gameSettings {
                                    gameSettings = settings
                                    showGame = true
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(peer.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                        Text("Tap to join")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
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
        .onAppear {
            startSearch()
        }
        .onDisappear {
            print("🎮 AvailableRoomsView: View disappeared, stopping search")
            gameRoom.stopBrowsing()
        }
    }
    
    private func startSearch() {
        print("🎮 AvailableRoomsView: Starting room search")
        isSearching = true
        searchStartTime = Date()
        gameRoom.startBrowsing()

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if isSearching {
                print("🎮 AvailableRoomsView: Search timeout reached")
                isSearching = false
            }
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(showGame: .constant(false), gameSettings: .constant(nil))
    }
} 
