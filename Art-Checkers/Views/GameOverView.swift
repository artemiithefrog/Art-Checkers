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
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                Button {
                    showGame = false
                } label: {
                    Text("Back to Menu")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.3, green: 0.8, blue: 0.6),
                                    Color(red: 0.3, green: 0.8, blue: 0.6).opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
            )
            .padding(.horizontal, 40)
        }
    }
} 
