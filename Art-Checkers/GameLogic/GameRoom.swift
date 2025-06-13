//
//  GameRoom.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 11.06.2025.
//

import Foundation
import MultipeerConnectivity

class GameRoom: NSObject, ObservableObject, GameSessionManagerDelegate {
    @Published var currentPlayer = "White"
    @Published var isHost: Bool = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var availablePeers: [MCPeerID] = []
    @Published var statusMessage: String = ""
    @Published var boardState: [[String]] = Array(repeating: Array(repeating: ".", count: 8), count: 8)
    @Published var initialBoard: [[Piece?]]?
    @Published var capturedWhitePieces: Int = 0
    @Published var capturedBlackPieces: Int = 0
    @Published var currentSettings: GameSettings?
    
    private let sessionManager: GameSessionManager
    
    override init() {
        sessionManager = GameSessionManager()
        super.init()
        sessionManager.delegate = self
        setupInitialBoardState()
    }
    
    private func setupInitialBoardState() {
        for row in 0..<8 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    if row < 3 {
                        boardState[row][col] = "B"
                    } else if row > 4 {
                        boardState[row][col] = "W"
                    }
                }
            }
        }
    }
    
    func cleanup() {
        sessionManager.cleanup()
        isHost = false
        currentSettings = nil
    }
    
    func startHosting(settings: GameSettings) {
        cleanup()
        isHost = true
        sessionManager.startHosting()
        currentSettings = settings
        
        if let peer = connectedPeers.first {
            sessionManager.sendGameSettings(settings)
        }
    }
    
    func startBrowsing() {
        cleanup()
        sessionManager.startBrowsing()
    }
    
    func sendInitialBoard(_ board: [[Piece?]]) {
        sessionManager.sendInitialBoard(board)
    }
    
    func sendGameSettings(_ settings: GameSettings) {
        sessionManager.sendGameSettings(settings)
    }
    
    func sendBoardState(_ board: [[Piece?]]) {
        sessionManager.sendBoardState(board, capturedWhite: capturedWhitePieces, capturedBlack: capturedBlackPieces)
    }
    
    func playerChanged(currentPlayer: String) {
        self.currentPlayer = currentPlayer
        sessionManager.sendCurrentPlayer(currentPlayer)
    }
    
    func connectToPeer(_ peer: MCPeerID) {
        sessionManager.connectToPeer(peer)
    }
    
    func connectToRandomRoom() {
        sessionManager.connectToRandomRoom()
    }
    
    // MARK: - GameSessionManagerDelegate
    
    func didReceiveBoardState(_ boardState: [[String]], capturedWhite: Int, capturedBlack: Int) {
        self.boardState = boardState
        self.capturedWhitePieces = capturedWhite
        self.capturedBlackPieces = capturedBlack
    }
    
    func didReceiveInitialBoard(_ board: [[Piece?]]) {
        self.initialBoard = board
    }
    
    func didReceiveGameSettings(_ settings: GameSettings) {
        self.currentSettings = settings
    }
    
    func didReceiveCurrentPlayer(_ player: String) {
        self.currentPlayer = player
    }
    
    func didUpdateConnectionStatus(_ status: String) {
        self.statusMessage = status
    }
    
    func didUpdateConnectedPeers(_ peers: [MCPeerID]) {
        self.connectedPeers = peers
    }
    
    func didUpdateAvailablePeers(_ peers: [MCPeerID]) {
        self.availablePeers = peers
    }
}
