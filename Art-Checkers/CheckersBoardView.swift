import SwiftUI

struct CheckersBoard: View {
    let board: [[String]]
    let squareSize: CGFloat
    let isHost: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<8) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8) { col in
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                                .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
            
            ForEach(0..<8) { row in
                ForEach(0..<8) { col in
                    if board[row][col] != "." {
                        let piece = board[row][col]
                        let displayRow = isHost ? row : 7 - row
                        let displayCol = isHost ? col : 7 - col
                        let position = CGPoint(
                            x: CGFloat(displayCol) * squareSize + squareSize / 2,
                            y: CGFloat(displayRow) * squareSize + squareSize / 2
                        )
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        piece.hasPrefix("W") ? Color.white : Color.black.opacity(0.8),
                                        piece.hasPrefix("W") ? Color.white.opacity(0.8) : Color.black
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: squareSize * 0.8, height: squareSize * 0.8)
                            .shadow(radius: 2)
                            .overlay(
                                Circle()
                                    .stroke(
                                        piece.hasPrefix("W") ? Color.black.opacity(0.3) : Color.white.opacity(0.3),
                                        lineWidth: 1
                                    )
                                    .padding(squareSize * 0.15)
                            )
                            .overlay(
                                Group {
                                    if piece.hasSuffix("K") {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(piece.hasPrefix("W") ? .black : .white)
                                            .font(.system(size: squareSize * 0.4))
                                    }
                                }
                            )
                            .position(position)
                    }
                }
            }
        }
    }
}

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
    @ObservedObject var gameRoom: GameRoom
    
    init(game: CheckersGame, selectedPosition: Binding<Position?>, draggedPiece: Binding<Piece?>, dragOffset: Binding<CGSize>, settings: GameSettings, showGame: Binding<Bool>, gameRoom: GameRoom) {
        self.game = game
        self._selectedPosition = selectedPosition
        self._draggedPiece = draggedPiece
        self._dragOffset = dragOffset
        self.settings = settings
        self._showGame = showGame
        self._whiteTimeRemaining = State(initialValue: Int(settings.timePerMove))
        self._blackTimeRemaining = State(initialValue: Int(settings.timePerMove))
        self._isFirstMove = State(initialValue: true)
        self.gameRoom = gameRoom
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    HStack {
                        Button(action: {
                            showExitAlert = true
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Current Player: \(game.currentPlayer == .white ? "White" : "Black")")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        if gameRoom.capturedWhitePieces > 0 {
                            HStack(spacing: -10) {
                                ForEach(0..<min(gameRoom.capturedWhitePieces, 5), id: \.self) { index in
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white, Color.white.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 30, height: 30)
                                        .shadow(radius: 2)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                                .padding(4)
                                        )
                                }
                            }
                        }
                    }
                    .frame(height: 30)
                    .padding(.horizontal)
                    
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
                            CheckersBoard(board: game.board.map { row in
                                row.map { piece in
                                    if let piece = piece {
                                        return piece.color == .white ? (piece.isKing ? "WK" : "W") : (piece.isKing ? "BK" : "B")
                                    }
                                    return "."
                                }
                            }, squareSize: squareSize, isHost: gameRoom.isHost)
                            
                            if let target = targetPosition {
                                let displayRow = gameRoom.isHost ? target.row : 7 - target.row
                                let displayCol = gameRoom.isHost ? target.col : 7 - target.col
                                Rectangle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: squareSize, height: squareSize)
                                    .position(
                                        x: CGFloat(displayCol) * squareSize + squareSize / 2,
                                        y: CGFloat(displayRow) * squareSize + squareSize / 2
                                    )
                            }
                            
                            if let selected = selectedPosition,
                               let piece = game.board[selected.row][selected.col] {
                                ForEach(Array(game.getPossibleMoves(for: piece)), id: \.self) { position in
                                    let displayRow = gameRoom.isHost ? position.row : 7 - position.row
                                    let displayCol = gameRoom.isHost ? position.col : 7 - position.col
                                    Circle()
                                        .fill(Color.green.opacity(0.3))
                                        .frame(width: squareSize * 0.3, height: squareSize * 0.3)
                                        .position(
                                            x: CGFloat(displayCol) * squareSize + squareSize / 2,
                                            y: CGFloat(displayRow) * squareSize + squareSize / 2
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
                            
                            ForEach(0..<8) { row in
                                ForEach(0..<8) { col in
                                    if let piece = game.board[row][col] {
                                        let isSelected = selectedPosition?.row == row && selectedPosition?.col == col
                                        let displayRow = gameRoom.isHost ? row : 7 - row
                                        let displayCol = gameRoom.isHost ? col : 7 - col
                                        
                                        if !isSelected {
                                            PieceView(piece: piece, size: squareSize * 0.8)
                                                .position(
                                                    x: CGFloat(displayCol) * squareSize + squareSize / 2,
                                                    y: CGFloat(displayRow) * squareSize + squareSize / 2
                                                )
                                                .onTapGesture {
                                                    if piece.color == game.currentPlayer && 
                                                       ((gameRoom.isHost && piece.color == settings.playerColor) || 
                                                        (!gameRoom.isHost && piece.color == settings.playerColor)) {
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
                                let displayRow = gameRoom.isHost ? selectedPosition.row : 7 - selectedPosition.row
                                let displayCol = gameRoom.isHost ? selectedPosition.col : 7 - selectedPosition.col
                                PieceView(piece: draggedPiece, size: squareSize * 0.8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.green, lineWidth: 2)
                                            .frame(width: squareSize * 0.8, height: squareSize * 0.8)
                                    )
                                    .position(
                                        x: CGFloat(displayCol) * squareSize + squareSize / 2,
                                        y: CGFloat(displayRow) * squareSize + squareSize / 2
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
                                                    x: CGFloat(displayCol) * squareSize + squareSize / 2 + value.translation.width,
                                                    y: CGFloat(displayRow) * squareSize + squareSize / 2 + value.translation.height
                                                )
                                                
                                                let targetCol = Int(round((pieceCenter.x - squareSize / 2) / squareSize))
                                                let targetRow = Int(round((pieceCenter.y - squareSize / 2) / squareSize))
                                                
                                                let actualTargetCol = gameRoom.isHost ? targetCol : 7 - targetCol
                                                let actualTargetRow = gameRoom.isHost ? targetRow : 7 - targetRow
                                                
                                                if actualTargetRow >= 0 && actualTargetRow < 8 && actualTargetCol >= 0 && actualTargetCol < 8 {
                                                    targetPosition = Position(row: actualTargetRow, col: actualTargetCol)
                                                } else {
                                                    targetPosition = nil
                                                }
                                            }
                                            .onEnded { value in
                                                let pieceCenter = CGPoint(
                                                    x: CGFloat(displayCol) * squareSize + squareSize / 2 + value.translation.width,
                                                    y: CGFloat(displayRow) * squareSize + squareSize / 2 + value.translation.height
                                                )
                                                
                                                let targetCol = Int(round((pieceCenter.x - squareSize / 2) / squareSize))
                                                let targetRow = Int(round((pieceCenter.y - squareSize / 2) / squareSize))
                                                
                                                let actualTargetCol = gameRoom.isHost ? targetCol : 7 - targetCol
                                                let actualTargetRow = gameRoom.isHost ? targetRow : 7 - targetRow
                                                
                                                if actualTargetRow >= 0 && actualTargetRow < 8 && actualTargetCol >= 0 && actualTargetCol < 8 {
                                                    let targetPosition = Position(row: actualTargetRow, col: actualTargetCol)
                                                    
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
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            moveOffset = CGSize(
                                                                width: CGFloat(actualTargetCol - selectedPosition.col) * squareSize,
                                                                height: CGFloat(actualTargetRow - selectedPosition.row) * squareSize
                                                            )
                                                        }
                                                        
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                                game.makeMove(from: selectedPosition, to: targetPosition)
                                                                if settings.timePerMove > 0 {
                                                                    resetTimers()
                                                                }
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
                    
                    HStack(spacing: 20) {
                        if gameRoom.capturedBlackPieces > 0 {
                            HStack(spacing: -10) {
                                ForEach(0..<min(gameRoom.capturedBlackPieces, 5), id: \.self) { index in
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 30, height: 30)
                                        .shadow(color: .white, radius: 2, x: 0, y: 0)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                .padding(4)
                                        )
                                }
                            }
                        }
                    }
                    .frame(height: 30)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                
                if game.gameOver, let winner = game.winner {
                    GameOverView(winner: winner, showGame: $showGame)
                }
            }
            .alert("Exit Game", isPresented: $showExitAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Exit", role: .destructive) {
                    game.reset()
                    showGame = false
                }
            } message: {
                Text("Are you sure you want to exit the game?")
            }
            .onAppear {
                game.reset()
                if settings.timePerMove > 0 {
                    startTimer()
                }
                
                if !gameRoom.isHost {
                    if let initialBoard = gameRoom.initialBoard {
                        game.board = initialBoard
                    }
                }
            }
            .onChange(of: gameRoom.boardState) { newBoardState in
                for row in 0..<8 {
                    for col in 0..<8 {
                        let pieceState = newBoardState[row][col]
                        if pieceState != "." {
                            let color: PieceColor = pieceState.hasPrefix("W") ? .white : .black
                            let isKing = pieceState.hasSuffix("K")
                            game.board[row][col] = Piece(color: color, type: isKing ? .king : .normal, position: Position(row: row, col: col))
                        } else {
                            game.board[row][col] = nil
                        }
                    }
                }
            }
            .onChange(of: gameRoom.currentPlayer) { newPlayer in
                game.currentPlayer = newPlayer == "White" ? .white : .black
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
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
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            piece.color == .white ? Color.white : Color.black.opacity(0.8),
                            piece.color == .white ? Color.white.opacity(0.8) : Color.black
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(radius: 2)
                .overlay(
                    Circle()
                        .stroke(
                            piece.color == .white ? Color.black.opacity(0.3) : Color.white.opacity(0.3),
                            lineWidth: 1
                        )
                        .padding(size * 0.15)
                )
            
            if piece.isKing {
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
        showGame: .constant(true),
        gameRoom: GameRoom()
    )
} 
