import SwiftUI

struct CheckersBoardView: View {
    @StateObject private var game = CheckersGame()
    @State private var selectedPosition: Position?
    
    var body: some View {
        VStack {
            Text("Current Player: \(game.currentPlayer == .white ? "White" : "Black")")
                .font(.title)
                .padding()
            
            BoardView(game: game, selectedPosition: $selectedPosition)
                .aspectRatio(1, contentMode: .fit)
                .padding()
        }
    }
}

struct BoardView: View {
    @ObservedObject var game: CheckersGame
    @Binding var selectedPosition: Position?
    
    var body: some View {
        GeometryReader { geometry in
            let squareSize = min(geometry.size.width, geometry.size.height) / 8
            
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<8) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<8) { col in
                                Rectangle()
                                    .fill((row + col) % 2 == 0 ? Color.brown.opacity(0.3) : Color.brown.opacity(0.7))
                                    .frame(width: squareSize, height: squareSize)
                            }
                        }
                    }
                }

                ForEach(0..<8) { row in
                    ForEach(0..<8) { col in
                        if let piece = game.board[row][col] {
                            PieceView(piece: piece, size: squareSize * 0.8)
                                .position(
                                    x: CGFloat(col) * squareSize + squareSize / 2,
                                    y: CGFloat(row) * squareSize + squareSize / 2
                                )
                                .onTapGesture {
                                    handlePieceTap(at: Position(row: row, col: col))
                                }
                        }
                    }
                }

                if let selected = selectedPosition,
                   let piece = game.board[selected.row][selected.col] {
                    ForEach(Array(game.getPossibleMoves(for: piece)), id: \.self) { position in
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: squareSize * 0.3, height: squareSize * 0.3)
                            .position(
                                x: CGFloat(position.col) * squareSize + squareSize / 2,
                                y: CGFloat(position.row) * squareSize + squareSize / 2
                            )
                            .onTapGesture {
                                game.makeMove(from: selected, to: position)
                                selectedPosition = nil
                            }
                    }
                }
            }
        }
    }
    
    private func handlePieceTap(at position: Position) {
        if let selected = selectedPosition {
            if selected == position {
                selectedPosition = nil
            } else if let piece = game.board[selected.row][selected.col],
                      game.isValidMove(from: selected, to: position) {
                game.makeMove(from: selected, to: position)
                selectedPosition = nil
            } else if let piece = game.board[position.row][position.col],
                      piece.color == game.currentPlayer {
                selectedPosition = position
            }
        } else if let piece = game.board[position.row][position.col],
                  piece.color == game.currentPlayer {
            selectedPosition = position
        }
    }
}

struct PieceView: View {
    let piece: Piece
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(piece.color == .white ? Color.white : Color.black)
                .frame(width: size, height: size)
                .shadow(radius: 2)
            
            if piece.type == .king {
                Image(systemName: "crown.fill")
                    .foregroundColor(piece.color == .white ? .black : .white)
                    .font(.system(size: size * 0.4))
            }
        }
    }
}

#Preview {
    CheckersBoardView()
} 
