import SwiftUI

struct MainMenuView: View {
    @State private var showNewGameSheet = false
    @State private var showSettingsSheet = false
    @EnvironmentObject var gameRoom: GameRoom
    @Binding var showGame: Bool
    @Binding var gameSettings: GameSettings?
    @State private var showGameView = false
    @State private var showConnectView = false
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
                            showConnectView = true
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
            .navigationDestination(isPresented: $showConnectView) {
                ConnectToRoomView(showGame: $showGameView)
                    .navigationBarBackButtonHidden()
                    .environmentObject(gameRoom)
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
