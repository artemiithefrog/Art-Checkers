import SwiftUI

struct GameOverView: View {
    let winner: PieceColor
    @Binding var showGame: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("Game Over!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(winner == .white ? "White" : "Black") wins!")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(winner == .white ? .white : .black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(winner == .white ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                    )
                
                HStack(spacing: 20) {
                    Button(action: {
                        showGame = false
                    }) {
                        Text("Main Menu")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // TODO: Start new game
                    }) {
                        Text("New Game")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.gray.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                    )
            )
            .padding(40)
        }
    }
} 