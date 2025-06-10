import Foundation

enum PieceColor {
    case white
    case black
}

enum PieceType {
    case normal
    case king
}

struct Piece: Identifiable {
    let id = UUID()
    var color: PieceColor
    var type: PieceType
    var position: Position
}

struct Position: Hashable {
    var row: Int
    var col: Int
}

class CheckersGame: ObservableObject {
    @Published var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    @Published var currentPlayer: PieceColor = .white
    @Published var selectedPiece: Piece?
    @Published var possibleMoves: Set<Position> = []
    @Published var hasCaptureMoves: Bool = false
    @Published var lastCapturePosition: Position?
    
    init() {
        setupBoard()
    }
    
    private func setupBoard() {
        for row in 0...2 {
            for col in 0...7 {
                if (row + col) % 2 == 1 {
                    board[row][col] = Piece(color: .black, type: .normal, position: Position(row: row, col: col))
                }
            }
        }
        
        for row in 5...7 {
            for col in 0...7 {
                if (row + col) % 2 == 1 {
                    board[row][col] = Piece(color: .white, type: .normal, position: Position(row: row, col: col))
                }
            }
        }
    }
    
    func getKingCaptureMoves(for piece: Piece, from: Position) -> Set<Position> {
        var moves: Set<Position> = []
        let directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        
        for (rowDir, colDir) in directions {
            var currentRow = from.row + rowDir
            var currentCol = from.col + colDir
            var foundPiece = false
            var captureRow = -1
            var captureCol = -1
            
            while currentRow >= 0 && currentRow < 8 && currentCol >= 0 && currentCol < 8 {
                if let currentPiece = board[currentRow][currentCol] {
                    if !foundPiece {
                        if currentPiece.color != piece.color {
                            foundPiece = true
                            captureRow = currentRow
                            captureCol = currentCol
                        } else {
                            break
                        }
                    } else {
                        if currentPiece.color == piece.color {
                            break
                        } else {
                            break
                        }
                    }
                } else if foundPiece {
                    moves.insert(Position(row: currentRow, col: currentCol))
                }
                currentRow += rowDir
                currentCol += colDir
            }
        }
        return moves
    }
    
    func getCaptureMovesForPiece(_ piece: Piece, from: Position) -> Set<Position> {
        if piece.type == .king {
            return getKingCaptureMoves(for: piece, from: from)
        }
        
        var moves: Set<Position> = []
        let directions = piece.type == .king ? [-1, 1] : [piece.color == .white ? -1 : 1]
        
        for rowDir in directions {
            for colDir in [-1, 1] {
                let captureRow = from.row + rowDir * 2
                let captureCol = from.col + colDir * 2
                
                if captureRow >= 0 && captureRow < 8 && captureCol >= 0 && captureCol < 8 {
                    let capturedRow = from.row + rowDir
                    let capturedCol = from.col + colDir
                    
                    if let capturedPiece = board[capturedRow][capturedCol],
                       capturedPiece.color != piece.color,
                       board[captureRow][captureCol] == nil {
                        moves.insert(Position(row: captureRow, col: captureCol))
                    }
                }
            }
        }
        return moves
    }
    
    func hasCaptureMovesForPiece(_ piece: Piece, from: Position) -> Bool {
        !getCaptureMovesForPiece(piece, from: from).isEmpty
    }
    
    func hasAnyCaptureMoves() -> Bool {
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col],
                   piece.color == currentPlayer,
                   hasCaptureMovesForPiece(piece, from: Position(row: row, col: col)) {
                    return true
                }
            }
        }
        return false
    }
    
    func isValidMove(from: Position, to: Position) -> Bool {
        guard let piece = board[from.row][from.col] else { return false }
        
        if piece.color != currentPlayer { return false }
        
        let rowDiff = to.row - from.row
        let colDiff = abs(to.col - from.col)
        
        if colDiff != abs(rowDiff) { return false }
        
        if board[to.row][to.col] != nil { return false }
        
        if let lastCapture = lastCapturePosition, lastCapture == from {
            if piece.type == .king {
                return isValidKingCapture(from: from, to: to)
            }
            if abs(rowDiff) != 2 { return false }
            
            let capturedRow = (from.row + to.row) / 2
            let capturedCol = (from.col + to.col) / 2
            
            guard let capturedPiece = board[capturedRow][capturedCol] else { return false }
            if capturedPiece.color == piece.color { return false }
            return true
        }
        
        if piece.type == .king {
            if hasAnyCaptureMoves() {
                return isValidKingCapture(from: from, to: to)
            }
            return isValidKingMove(from: from, to: to)
        }
        
        if abs(rowDiff) == 1 && abs(colDiff) == 1 {
            if hasAnyCaptureMoves() {
                return false
            }
            
            if piece.color == .white && rowDiff >= 0 { return false }
            if piece.color == .black && rowDiff <= 0 { return false }
            
            return true
        }
        
        if abs(rowDiff) == 2 && abs(colDiff) == 2 {
            let capturedRow = (from.row + to.row) / 2
            let capturedCol = (from.col + to.col) / 2
            
            guard let capturedPiece = board[capturedRow][capturedCol] else { return false }
            if capturedPiece.color == piece.color { return false }
            return true
        }
        
        return false
    }
    
    func isValidKingMove(from: Position, to: Position) -> Bool {
        let rowDiff = to.row - from.row
        let colDiff = to.col - from.col
        
        if abs(rowDiff) != abs(colDiff) { return false }
        
        let rowDir = rowDiff > 0 ? 1 : -1
        let colDir = colDiff > 0 ? 1 : -1
        
        var currentRow = from.row + rowDir
        var currentCol = from.col + colDir
        
        while currentRow != to.row && currentCol != to.col {
            if board[currentRow][currentCol] != nil {
                return false
            }
            currentRow += rowDir
            currentCol += colDir
        }
        
        return true
    }
    
    func isValidKingCapture(from: Position, to: Position) -> Bool {
        let rowDiff = to.row - from.row
        let colDiff = to.col - from.col
        
        if abs(rowDiff) != abs(colDiff) { return false }
        
        let rowDir = rowDiff > 0 ? 1 : -1
        let colDir = colDiff > 0 ? 1 : -1
        
        var currentRow = from.row + rowDir
        var currentCol = from.col + colDir
        var foundPiece = false
        
        while currentRow != to.row && currentCol != to.col {
            if let piece = board[currentRow][currentCol] {
                if !foundPiece {
                    if piece.color != board[from.row][from.col]!.color {
                        foundPiece = true
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            }
            currentRow += rowDir
            currentCol += colDir
        }
        
        return foundPiece
    }
    
    func makeMove(from: Position, to: Position) {
        guard isValidMove(from: from, to: to) else { return }
        
        var piece = board[from.row][from.col]!
        piece.position = to
        board[to.row][to.col] = piece
        board[from.row][from.col] = nil
        
        if piece.type == .king {
            let rowDiff = to.row - from.row
            let colDiff = to.col - from.col
            let rowDir = rowDiff > 0 ? 1 : -1
            let colDir = colDiff > 0 ? 1 : -1
            
            var currentRow = from.row + rowDir
            var currentCol = from.col + colDir
            
            while currentRow != to.row && currentCol != to.col {
                if board[currentRow][currentCol] != nil {
                    board[currentRow][currentCol] = nil
                    if hasCaptureMovesForPiece(piece, from: to) {
                        lastCapturePosition = to
                        return
                    }
                    break
                }
                currentRow += rowDir
                currentCol += colDir
            }
        } else {
            let rowDiff = to.row - from.row
            let colDiff = to.col - from.col
            if abs(rowDiff) == 2 {
                let capturedRow = (from.row + to.row) / 2
                let capturedCol = (from.col + to.col) / 2
                board[capturedRow][capturedCol] = nil
                
                if hasCaptureMovesForPiece(piece, from: to) {
                    lastCapturePosition = to
                    return
                }
            }
        }
        
        if (piece.color == .white && to.row == 0) || (piece.color == .black && to.row == 7) {
            piece.type = .king
            board[to.row][to.col] = piece
        }
        
        lastCapturePosition = nil
        currentPlayer = currentPlayer == .white ? .black : .white
    }
    
    func getPossibleMoves(for piece: Piece) -> Set<Position> {
        if let lastCapture = lastCapturePosition, lastCapture == piece.position {
            return getCaptureMovesForPiece(piece, from: piece.position)
        }
        
        let backwardCaptureMoves = getBackwardCaptureMoves(for: piece)
        if !backwardCaptureMoves.isEmpty {
            return backwardCaptureMoves
        }
        
        let forwardCaptureMoves = getCaptureMovesForPiece(piece, from: piece.position)
        if !forwardCaptureMoves.isEmpty {
            return forwardCaptureMoves
        }
        
        var moves: Set<Position> = []
        if piece.type == .king {
            let directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
            for (rowDir, colDir) in directions {
                var currentRow = piece.position.row + rowDir
                var currentCol = piece.position.col + colDir
                
                while currentRow >= 0 && currentRow < 8 && currentCol >= 0 && currentCol < 8 {
                    if board[currentRow][currentCol] == nil {
                        moves.insert(Position(row: currentRow, col: currentCol))
                    } else {
                        break
                    }
                    currentRow += rowDir
                    currentCol += colDir
                }
            }
        } else {
            let directions = piece.color == .white ? [-1] : [1]
            for rowDir in directions {
                for colDir in [-1, 1] {
                    let newRow = piece.position.row + rowDir
                    let newCol = piece.position.col + colDir
                    
                    if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
                        let newPos = Position(row: newRow, col: newCol)
                        if isValidMove(from: piece.position, to: newPos) {
                            moves.insert(newPos)
                        }
                    }
                }
            }
        }
        
        return moves
    }
    
    func hasBackwardCaptureMoves(for piece: Piece) -> Bool {
        if piece.type == .king {
            return !getKingCaptureMoves(for: piece, from: piece.position).isEmpty
        }
        
        let backwardDirection = piece.color == .white ? 1 : -1
        
        for colDir in [-1, 1] {
            let captureRow = piece.position.row + backwardDirection * 2
            let captureCol = piece.position.col + colDir * 2
            
            if captureRow >= 0 && captureRow < 8 && captureCol >= 0 && captureCol < 8 {
                let capturedRow = piece.position.row + backwardDirection
                let capturedCol = piece.position.col + colDir
                
                if let capturedPiece = board[capturedRow][capturedCol],
                   capturedPiece.color != piece.color,
                   board[captureRow][captureCol] == nil {
                    return true
                }
            }
        }
        return false
    }
    
    func getBackwardCaptureMoves(for piece: Piece) -> Set<Position> {
        if piece.type == .king {
            return getKingCaptureMoves(for: piece, from: piece.position)
        }
        
        var moves: Set<Position> = []
        let backwardDirection = piece.color == .white ? 1 : -1
        
        for colDir in [-1, 1] {
            let captureRow = piece.position.row + backwardDirection * 2
            let captureCol = piece.position.col + colDir * 2
            
            if captureRow >= 0 && captureRow < 8 && captureCol >= 0 && captureCol < 8 {
                let capturedRow = piece.position.row + backwardDirection
                let capturedCol = piece.position.col + colDir
                
                if let capturedPiece = board[capturedRow][capturedCol],
                   capturedPiece.color != piece.color,
                   board[captureRow][captureCol] == nil {
                    moves.insert(Position(row: captureRow, col: captureCol))
                }
            }
        }
        return moves
    }
} 
