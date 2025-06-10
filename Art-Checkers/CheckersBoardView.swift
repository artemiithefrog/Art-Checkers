import SwiftUI

struct CheckersBoardView: View {
    @ObservedObject var game: CheckersGame
    @Binding var selectedPosition: Position?
    @Binding var draggedPiece: Piece?
    @Binding var dragOffset: CGSize
    let settings: GameSettings
    @Binding var showGame: Bool
    @State private var targetPosition: Position?
    @State private var possibleMovesOpacity: Double = 0
    @State private var moveOffset: CGSize = .zero
    @State private var isMoving: Bool = false
    @State private var showExitAlert = false
    @State private var whiteTimeRemaining: Int
    @State private var blackTimeRemaining: Int
    @State private var timer: Timer?
    @State private var isFirstMove = true
    
    init(game: CheckersGame, selectedPosition: Binding<Position?>, draggedPiece: Binding<Piece?>, dragOffset: Binding<CGSize>, settings: GameSettings, showGame: Binding<Bool>) {
        self.game = game
        self._selectedPosition = selectedPosition
        self._draggedPiece = draggedPiece
        self._dragOffset = dragOffset
        self.settings = settings
        self._showGame = showGame
        self._whiteTimeRemaining = State(initialValue: Int(settings.timePerMove))
        self._blackTimeRemaining = State(initialValue: Int(settings.timePerMove))
        self._isFirstMove = State(initialValue: true)
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        showExitAlert = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text("Current Player: \(game.currentPlayer == .white ? "White" : "Black")")
                        .font(.title)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal)

                Spacer()
                 
                HStack {
                    if settings.timePerMove > 0 {
                        HStack {
                            Text("\(formatTime(blackTimeRemaining))")
                                .font(.system(.title2, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, -20)
                    }
                    Spacer()
                }
                GeometryReader { geometry in
                    let squareSize = min(geometry.size.width, geometry.size.height) / 8
                    
                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(0..<8) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<8) { col in
                                        Rectangle()
                                            .fill((row + col) % 2 == 0 ? getLightColor() : getDarkColor())
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
                                                    if settings.timePerMove > 0 {
                                                        resetTimers()
                                                    }
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
                                                        if settings.timePerMove > 0 {
                                                            resetTimers()
                                                        }
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
                .aspectRatio(1, contentMode: .fit)
                .padding()
                
                HStack {
                    if settings.timePerMove > 0 {
                        HStack {
                            Text("\(formatTime(whiteTimeRemaining))")
                                .font(.system(.title2, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        .padding(.horizontal)
                        .padding(.top, -20)
                    }
                    Spacer()
                }
                Spacer()
            }
            
            if game.gameOver, let winner = game.winner {
                GameOverView(winner: winner, showGame: $showGame)
            }
        }
        .alert("Exit Game", isPresented: $showExitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                showGame = false
            }
        } message: {
            Text("Are you sure you want to exit the game?")
        }
        .onAppear {
            if settings.timePerMove > 0 {
                startTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func getLightColor() -> Color {
        let styles: [(light: Color, dark: Color)] = [
            (Color.brown.opacity(0.3), Color.brown.opacity(0.7)),
            (Color.green.opacity(0.3), Color.green.opacity(0.7)),
            (Color.blue.opacity(0.3), Color.blue.opacity(0.7)),
            (Color.gray.opacity(0.3), Color.gray.opacity(0.7)),
            (Color.purple.opacity(0.3), Color.purple.opacity(0.7)),
            (Color.orange.opacity(0.3), Color.orange.opacity(0.7)),
            (Color.red.opacity(0.3), Color.red.opacity(0.7)),
            (Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3), Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.7))
        ]
        return styles[settings.boardStyle].light
    }
    
    private func getDarkColor() -> Color {
        let styles: [(light: Color, dark: Color)] = [
            (Color.brown.opacity(0.3), Color.brown.opacity(0.7)),
            (Color.green.opacity(0.3), Color.green.opacity(0.7)),
            (Color.blue.opacity(0.3), Color.blue.opacity(0.7)),
            (Color.gray.opacity(0.3), Color.gray.opacity(0.7)),
            (Color.purple.opacity(0.3), Color.purple.opacity(0.7)),
            (Color.orange.opacity(0.3), Color.orange.opacity(0.7)),
            (Color.red.opacity(0.3), Color.red.opacity(0.7)),
            (Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3), Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.7))
        ]
        return styles[settings.boardStyle].dark
    }
    
    private func calculatePieceOverlap(pieceCenter: CGPoint, targetSquare: CGPoint, pieceSize: CGFloat, squareSize: CGFloat) -> CGFloat {
        let pieceRect = CGRect(
            x: pieceCenter.x - pieceSize / 2,
            y: pieceCenter.y - pieceSize / 2,
            width: pieceSize,
            height: pieceSize
        )
        
        let squareRect = CGRect(
            x: targetSquare.x - squareSize / 2,
            y: targetSquare.y - squareSize / 2,
            width: squareSize,
            height: squareSize
        )
        
        let intersection = pieceRect.intersection(squareRect)
        let intersectionArea = intersection.width * intersection.height
        let pieceArea = pieceSize * pieceSize
        
        return intersectionArea / pieceArea
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func startTimer() {
        if isFirstMove {
            return
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if game.currentPlayer == .white {
                if whiteTimeRemaining > 0 {
                    whiteTimeRemaining -= 1
                } else {
                    timer?.invalidate()
                    game.gameOver = true
                    game.winner = .black
                }
            } else {
                if blackTimeRemaining > 0 {
                    blackTimeRemaining -= 1
                } else {
                    timer?.invalidate()
                    game.gameOver = true
                    game.winner = .white
                }
            }
        }
    }
    
    private func resetTimers() {
        whiteTimeRemaining = Int(settings.timePerMove)
        blackTimeRemaining = Int(settings.timePerMove)
        isFirstMove = false
        startTimer()
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
    CheckersBoardView(
        game: CheckersGame(),
        selectedPosition: .constant(nil),
        draggedPiece: .constant(nil),
        dragOffset: .constant(.zero),
        settings: GameSettings(
            playerColor: .white,
            timerMode: .noLimit,
            timePerMove: 30,
            boardStyle: 0
        ),
        showGame: .constant(true)
    )
} 
