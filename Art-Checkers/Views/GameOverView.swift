import SwiftUI

struct GameOverView: View {
    let winner: PieceColor?
    @Binding var showGame: Bool
    let reason: String
    let isDraw: Bool
    
    init(winner: PieceColor?, showGame: Binding<Bool>, reason: String = "", isDraw: Bool = false) {
        self.winner = winner
        self._showGame = showGame
        self.reason = reason
        self.isDraw = isDraw
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("Game Over!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    if isDraw {
                        Text("Draw!")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.2))
                            )
                    } else if let winner = winner {
                        Text("\(winner == .white ? "White" : "Black") wins!")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(winner == .white ? .white : .black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(winner == .white ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                            )
                    }
                    
                    if !reason.isEmpty {
                        Text(reason)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
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
