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
    @State private var showExitAlert = false
    @State private var whiteTimeRemaining: Int
    @State private var blackTimeRemaining: Int
    @State private var timer: Timer?
    @State private var isFirstMove = true
    @ObservedObject var gameRoom: GameRoom
    @State private var movingPiece: (piece: Piece, from: Position, to: Position)?
    @State private var moveProgress: CGFloat = 0
    @State private var opponentMove: (piece: Piece, from: Position, to: Position)?
    @State private var opponentMoveProgress: CGFloat = 0
    @State private var capturedPiece: (piece: Piece, position: Position)?
    @State private var capturedPieceOpacity: Double = 1.0
    
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
                        Button(action: { showExitAlert = true }) {
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
                                ForEach(0..<min(gameRoom.capturedWhitePieces, 5), id: \.self) { _ in
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
                                Text("\(formatTime(gameRoom.isHost ? blackTimeRemaining : whiteTimeRemaining))")
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
                            CheckersBoard(
                                board: game.board.map { row in
                                    row.map { piece in
                                        if let piece = piece {
                                            return piece.color == .white ? (piece.isKing ? "WK" : "W") : (piece.isKing ? "BK" : "B")
                                        }
                                        return "."
                                    }
                                },
                                squareSize: squareSize,
                                isHost: gameRoom.isHost,
                                boardStyle: settings.boardStyle
                            )
                            
                            if let target = targetPosition {
                                let displayRow = gameRoom.isHost ? target.row : 7 - target.row
                                let displayCol = gameRoom.isHost ? target.col : 7 - target.col
                                Rectangle()
                                    .fill(Color.green.opacity(0.3))
                                    .frame(width: squareSize, height: squareSize)
                                    .position(
                                        x: CGFloat(displayCol) * squareSize + squareSize / 2,
                                        y: CGFloat(displayRow) * squareSize + squareSize / 2
                                    )
                            }
                            
                            ForEach(0..<8) { row in
                                ForEach(0..<8) { col in
                                    if let piece = game.board[row][col] {
                                        let isSelected = selectedPosition?.row == row && selectedPosition?.col == col
                                        let displayRow = gameRoom.isHost ? row : 7 - row
                                        let displayCol = gameRoom.isHost ? col : 7 - col
                                        
                                        let isMoving = movingPiece?.from.row == row && movingPiece?.from.col == col
                                        let isOpponentMoving = opponentMove?.from.row == row && opponentMove?.from.col == col
                                        
                                        if !isMoving && !isOpponentMoving {
                                            let hasValidMoves = !game.getPossibleMoves(for: piece).isEmpty
                                            let hasCaptureMoves = game.hasCaptureMovesForPiece(piece, from: Position(row: row, col: col))
                                            let isCurrentPlayerPiece = piece.color == game.currentPlayer && 
                                                                      ((gameRoom.isHost && piece.color == settings.playerColor) || 
                                                                       (!gameRoom.isHost && piece.color == settings.playerColor))
                                            
                                            PieceView(piece: piece, size: squareSize * 0.8)
                                                .overlay(
                                                    isSelected ? Circle()
                                                        .stroke(
                                                            hasCaptureMoves ? Color.green : (hasValidMoves ? Color.green : Color.red),
                                                            lineWidth: 2
                                                        )
                                                        .frame(width: squareSize * 0.8, height: squareSize * 0.8) : nil
                                                )
                                                .position(
                                                    x: CGFloat(displayCol) * squareSize + squareSize / 2,
                                                    y: CGFloat(displayRow) * squareSize + squareSize / 2
                                                )
                                                .onTapGesture {
                                                    if isCurrentPlayerPiece {
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
                            
                            if let moving = movingPiece {
                                let fromRow = gameRoom.isHost ? moving.from.row : 7 - moving.from.row
                                let fromCol = gameRoom.isHost ? moving.from.col : 7 - moving.from.col
                                let toRow = gameRoom.isHost ? moving.to.row : 7 - moving.to.row
                                let toCol = gameRoom.isHost ? moving.to.col : 7 - moving.to.col
                                
                                PieceView(piece: moving.piece, size: squareSize * 0.8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.green, lineWidth: 2)
                                            .frame(width: squareSize * 0.8, height: squareSize * 0.8)
                                    )
                                    .position(
                                        x: CGFloat(fromCol) * squareSize + squareSize / 2 + 
                                           (CGFloat(toCol - fromCol) * squareSize * moveProgress),
                                        y: CGFloat(fromRow) * squareSize + squareSize / 2 + 
                                           (CGFloat(toRow - fromRow) * squareSize * moveProgress)
                                    )
                                    .zIndex(1)
                            }
                            
                            if let opponentMove = opponentMove {
                                let fromRow = gameRoom.isHost ? opponentMove.from.row : 7 - opponentMove.from.row
                                let fromCol = gameRoom.isHost ? opponentMove.from.col : 7 - opponentMove.from.col
                                let toRow = gameRoom.isHost ? opponentMove.to.row : 7 - opponentMove.to.row
                                let toCol = gameRoom.isHost ? opponentMove.to.col : 7 - opponentMove.to.col
                                
                                PieceView(piece: opponentMove.piece, size: squareSize * 0.8)
                                    .position(
                                        x: CGFloat(fromCol) * squareSize + squareSize / 2 + 
                                           (CGFloat(toCol - fromCol) * squareSize * opponentMoveProgress),
                                        y: CGFloat(fromRow) * squareSize + squareSize / 2 + 
                                           (CGFloat(toRow - fromRow) * squareSize * opponentMoveProgress)
                                    )
                                    .zIndex(1)
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
                                                movePiece(from: selected, to: position)
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding()
                    
                    HStack {
                        if settings.timePerMove > 0 {
                            HStack {
                                Text("\(formatTime(gameRoom.isHost ? whiteTimeRemaining : blackTimeRemaining))")
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
                                ForEach(0..<min(gameRoom.capturedBlackPieces, 5), id: \.self) { _ in
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
                
                if game.gameOver {
                    if game.isDraw {
                        GameOverView(
                            winner: nil,
                            showGame: $showGame,
                            reason: "Both players have only kings left",
                            isDraw: true
                        )
                    } else if let winner = game.winner {
                        GameOverView(
                            winner: winner,
                            showGame: $showGame,
                            reason: endgameReason(winner: winner),
                            isDraw: false
                        )
                    }
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
                game.gameRoom = gameRoom
                if !gameRoom.isHost {
                    game.currentPlayer = .black
                }

                if gameRoom.isHost {
                    game.checkGameOver()
                }
                
                setInitialTimerValues()
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name("TimerValuesReceived"), object: nil, queue: .main) { notification in
                    if let timerValues = notification.object as? [String: Int],
                       let initialWhiteTime = timerValues["initialWhiteTime"],
                       let initialBlackTime = timerValues["initialBlackTime"] {
                        whiteTimeRemaining = initialWhiteTime
                        blackTimeRemaining = initialBlackTime
                        if settings.timePerMove > 0 && gameRoom.isHost {
                            startTimer()
                        }
                    }
                }
            }
            .onChange(of: gameRoom.boardState) { newBoardState in
                var fromPosition: Position?
                var toPosition: Position?
                var movedPiece: Piece?

                gameRoom.capturedWhitePieces = game.capturedWhitePieces
                gameRoom.capturedBlackPieces = game.capturedBlackPieces
                
                for row in 0..<8 {
                    for col in 0..<8 {
                        let oldPiece = game.board[row][col]
                        let newPieceState = newBoardState[row][col]
                        
                        if oldPiece != nil && newPieceState == "." {
                            fromPosition = Position(row: row, col: col)
                            movedPiece = oldPiece
                        }
                        
                        if oldPiece == nil && newPieceState != "." {
                            toPosition = Position(row: row, col: col)
                        }
                    }
                }
                
                if let from = fromPosition, let to = toPosition, let piece = movedPiece {
                    opponentMove = (piece: piece, from: from, to: to)
                    opponentMoveProgress = 0
                    game.board[from.row][from.col] = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            opponentMoveProgress = 1
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        for row in 0..<8 {
                            for col in 0..<8 {
                                let pieceState = newBoardState[row][col]
                                if pieceState != "." {
                                    let color: PieceColor = pieceState.hasPrefix("W") ? .white : .black
                                    let isKing = pieceState.hasSuffix("K")
                                    let position = Position(row: row, col: col)
                                    var piece = Piece(color: color, type: isKing ? .king : .normal, position: position)
                                    piece.isKing = isKing
                                    game.board[row][col] = piece
                                } else {
                                    game.board[row][col] = nil
                                }
                            }
                        }
                        opponentMove = nil
                        opponentMoveProgress = 0

                        game.checkGameOver()

                        var whitePieces = 0
                        var blackPieces = 0
                        
                        for r in 0..<8 {
                            for c in 0..<8 {
                                if let p = game.board[r][c] {
                                    if p.color == .white {
                                        whitePieces += 1
                                    } else {
                                        blackPieces += 1
                                    }
                                }
                            }
                        }
                        
                        if whitePieces == 0 {
                            game.gameOver = true
                            game.winner = .black
                        } else if blackPieces == 0 {
                            game.gameOver = true
                            game.winner = .white
                        }
                    }
                }
            }
            .onChange(of: gameRoom.currentPlayer) { newPlayer in
                game.currentPlayer = newPlayer == "White" ? .white : .black
                
                if !gameRoom.isHost && isFirstMove && newPlayer == "Black" {
                    isFirstMove = false
                    if settings.timePerMove > 0 {
                        startTimer()
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    private func movePiece(from: Position, to: Position) {
        guard let piece = game.board[from.row][from.col] else { return }
        
        let rowDiff = to.row - from.row
        let colDiff = abs(to.col - from.col)
        
        if abs(rowDiff) == 2 && abs(colDiff) == 2 {
            let capturedRow = (from.row + to.row) / 2
            let capturedCol = (from.col + to.col) / 2
            
            if let capturedPiece = game.board[capturedRow][capturedCol] {
                if capturedPiece.color == .white {
                    game.capturedWhitePieces += 1
                    if let gameRoom = game.gameRoom {
                        gameRoom.capturedWhitePieces = game.capturedWhitePieces
                    }
                } else {
                    game.capturedBlackPieces += 1
                    if let gameRoom = game.gameRoom {
                        gameRoom.capturedBlackPieces = game.capturedBlackPieces
                    }
                }
            }
            
                if let capturedPiece = game.board[capturedRow][capturedCol] {
                let capturedColor = capturedPiece.color
                game.board[capturedRow][capturedCol] = nil

                var remainingPieces = 0
                for r in 0..<8 {
                    for c in 0..<8 {
                        if let p = game.board[r][c], p.color == capturedColor {
                            remainingPieces += 1
                        }
                    }
                }

                if remainingPieces == 0 {
                    game.gameOver = true
                    game.winner = capturedColor == .white ? .black : .white
                }
            }
        }
        
        movingPiece = (piece: piece, from: from, to: to)
        moveProgress = 0
        game.board[from.row][from.col] = nil
        
        game.currentPlayer = game.currentPlayer == .white ? .black : .white
        if let gameRoom = game.gameRoom {
            gameRoom.playerChanged(currentPlayer: game.currentPlayer == .white ? "White" : "Black")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                moveProgress = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            var updatedPiece = piece
            updatedPiece.position = to
            
            if (piece.color == .white && to.row == 0) || (piece.color == .black && to.row == 7) {
                updatedPiece.type = .king
                updatedPiece.isKing = true
            }
            
            game.board[to.row][to.col] = updatedPiece
            
            if settings.timePerMove > 0 {
                resetTimers()
            }
            
            if let gameRoom = game.gameRoom {
                gameRoom.sendBoardState(game.board)
            }
            
            game.checkGameOver()
            
            movingPiece = nil
            moveProgress = 0
            draggedPiece = nil
            selectedPosition = nil
            targetPosition = nil
            possibleMovesOpacity = 0
            dragOffset = .zero
        }
    }
    
    private func setInitialTimerValues() {
        if settings.timePerMove > 0 {
            whiteTimeRemaining = Int(settings.timePerMove)
            blackTimeRemaining = Int(settings.timePerMove)
        }
    }
    
    private func resetTimers() {
        if settings.timePerMove > 0 {
            if game.currentPlayer == .white {
                blackTimeRemaining = Int(settings.timePerMove)
            } else {
                whiteTimeRemaining = Int(settings.timePerMove)
            }
            isFirstMove = false
            startTimer()
        }
    }
    
    private func startTimer() {
        if isFirstMove || settings.timePerMove <= 0 {
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
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    func endgameReason(winner: PieceColor) -> String {
        if settings.timePerMove > 0 {
            if whiteTimeRemaining <= 0 {
                return "White player ran out of time"
            } else if blackTimeRemaining <= 0 {
                return "Black player ran out of time"
            }
        }

        if !game.hasAnyValidMoves(for: winner == .white ? .black : .white) {
            return "\(winner == .white ? "Black" : "White") pieces are blocked"
        } else {
            return "\(winner == .white ? "Black" : "White") pieces are captured"
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
