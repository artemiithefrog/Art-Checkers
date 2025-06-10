import SwiftUI

struct CheckersBoardView: View {
    @StateObject private var game = CheckersGame()
    @State private var selectedPosition: Position?
    @State private var draggedPiece: Piece?
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            Text("Current Player: \(game.currentPlayer == .white ? "White" : "Black")")
                .font(.title)
                .padding()
            
            BoardView(game: game, selectedPosition: $selectedPosition, draggedPiece: $draggedPiece, dragOffset: $dragOffset)
                .aspectRatio(1, contentMode: .fit)
                .padding()
        }
    }
}

struct BoardView: View {
    @ObservedObject var game: CheckersGame
    @Binding var selectedPosition: Position?
    @Binding var draggedPiece: Piece?
    @Binding var dragOffset: CGSize
    @State private var targetPosition: Position?
    @State private var possibleMovesOpacity: Double = 0
    @State private var moveOffset: CGSize = .zero
    @State private var isMoving: Bool = false
    
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
                
                if let target = targetPosition {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: squareSize, height: squareSize)
                        .position(
                            x: CGFloat(target.col) * squareSize + squareSize / 2,
                            y: CGFloat(target.row) * squareSize + squareSize / 2
                        )
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
                            .opacity(possibleMovesOpacity)
                            .onTapGesture {
                                if game.isValidMove(from: selected, to: position) {
                                    let rowDiff = position.row - selected.row
                                    let colDiff = position.col - selected.col
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isMoving = true
                                        moveOffset = CGSize(
                                            width: CGFloat(colDiff) * squareSize,
                                            height: CGFloat(rowDiff) * squareSize
                                        )
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            game.makeMove(from: selected, to: position)
                                            self.draggedPiece = nil
                                            self.selectedPosition = nil
                                            self.targetPosition = nil
                                            self.possibleMovesOpacity = 0
                                            self.moveOffset = .zero
                                            self.isMoving = false
                                        }
                                    }
                                }
                            }
                    }
                }
                
                ForEach(0..<8) { row in
                    ForEach(0..<8) { col in
                        if let piece = game.board[row][col] {
                            let isSelected = selectedPosition?.row == row && selectedPosition?.col == col
                            
                            if !isSelected {
                                PieceView(piece: piece, size: squareSize * 0.8)
                                    .position(
                                        x: CGFloat(col) * squareSize + squareSize / 2,
                                        y: CGFloat(row) * squareSize + squareSize / 2
                                    )
                                    .onTapGesture {
                                        if piece.color == game.currentPlayer {
                                            selectedPosition = Position(row: row, col: col)
                                            draggedPiece = piece
                                            dragOffset = .zero
                                            possibleMovesOpacity = 1
                                        }
                                    }
                            }
                        }
                    }
                }
                
                if let draggedPiece = draggedPiece,
                   let selectedPosition = selectedPosition {
                    PieceView(piece: draggedPiece, size: squareSize * 0.8)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 2)
                                .frame(width: squareSize * 0.8, height: squareSize * 0.8)
                        )
                        .position(
                            x: CGFloat(selectedPosition.col) * squareSize + squareSize / 2,
                            y: CGFloat(selectedPosition.row) * squareSize + squareSize / 2
                        )
                        .offset(isMoving ? moveOffset : dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if dragOffset == .zero {
                                        dragOffset = value.translation
                                    } else {
                                        dragOffset = value.translation
                                    }
                                    
                                    let pieceCenter = CGPoint(
                                        x: CGFloat(selectedPosition.col) * squareSize + squareSize / 2 + value.translation.width,
                                        y: CGFloat(selectedPosition.row) * squareSize + squareSize / 2 + value.translation.height
                                    )
                                    
                                    let targetCol = Int(round((pieceCenter.x - squareSize / 2) / squareSize))
                                    let targetRow = Int(round((pieceCenter.y - squareSize / 2) / squareSize))
                                    
                                    if targetRow >= 0 && targetRow < 8 && targetCol >= 0 && targetCol < 8 {
                                        targetPosition = Position(row: targetRow, col: targetCol)
                                    } else {
                                        targetPosition = nil
                                    }
                                }
                                .onEnded { value in
                                    let pieceCenter = CGPoint(
                                        x: CGFloat(selectedPosition.col) * squareSize + squareSize / 2 + value.translation.width,
                                        y: CGFloat(selectedPosition.row) * squareSize + squareSize / 2 + value.translation.height
                                    )
                                    
                                    let targetCol = Int(round((pieceCenter.x - squareSize / 2) / squareSize))
                                    let targetRow = Int(round((pieceCenter.y - squareSize / 2) / squareSize))
                                    
                                    if targetRow >= 0 && targetRow < 8 && targetCol >= 0 && targetCol < 8 {
                                        let targetPosition = Position(row: targetRow, col: targetCol)
                                        
                                        let pieceOverlap = calculatePieceOverlap(
                                            pieceCenter: pieceCenter,
                                            targetSquare: CGPoint(
                                                x: CGFloat(targetCol) * squareSize + squareSize / 2,
                                                y: CGFloat(targetRow) * squareSize + squareSize / 2
                                            ),
                                            pieceSize: squareSize * 0.8,
                                            squareSize: squareSize
                                        )
                                        
                                        if pieceOverlap >= 0.4 && game.isValidMove(from: selectedPosition, to: targetPosition) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                game.makeMove(from: selectedPosition, to: targetPosition)
                                            }
                                        } else {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                dragOffset = .zero
                                            }
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            dragOffset = .zero
                                        }
                                    }
                                    
                                    self.draggedPiece = nil
                                    self.selectedPosition = nil
                                    self.targetPosition = nil
                                    self.possibleMovesOpacity = 0
                                }
                        )
                }
            }
        }
    }
    
    private func calculatePieceOverlap(pieceCenter: CGPoint, targetSquare: CGPoint, pieceSize: CGFloat, squareSize: CGFloat) -> CGFloat {
        let pieceBounds = CGRect(
            x: pieceCenter.x - pieceSize/2,
            y: pieceCenter.y - pieceSize/2,
            width: pieceSize,
            height: pieceSize
        )
        
        let squareBounds = CGRect(
            x: targetSquare.x - squareSize/2,
            y: targetSquare.y - squareSize/2,
            width: squareSize,
            height: squareSize
        )
        
        let intersection = pieceBounds.intersection(squareBounds)
        let intersectionArea = intersection.width * intersection.height
        let pieceArea = pieceSize * pieceSize
        
        return intersectionArea / pieceArea
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
