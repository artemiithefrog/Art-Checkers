//
//  GameSessionManagerDelegate.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 13.06.2025.
//

import Foundation
import MultipeerConnectivity

class GameSessionManager: NSObject {
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private let serviceType = "checkers-game"
    private let peerID: MCPeerID
    
    weak var delegate: GameSessionManagerDelegate?
    
    override init() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        delegate?.didUpdateConnectionStatus("Сессия создана")
    }
    
    func cleanup() {
        for peer in session?.connectedPeers ?? [] {
            session?.cancelConnectPeer(peer)
        }
        
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        
        delegate?.didUpdateConnectedPeers([])
        delegate?.didUpdateAvailablePeers([])
        
        setupSession()
    }
    
    func startHosting() {
        cleanup()
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    func startBrowsing() {
        cleanup()
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        delegate?.didUpdateConnectionStatus("Поиск комнат...")
    }
    
    func sendInitialBoard(_ board: [[Piece?]]) {
        guard let session = session else { return }
        let boardData = try? JSONEncoder().encode(["initialBoard": board])
        try? session.send(boardData ?? Data(), toPeers: session.connectedPeers, with: .reliable)
    }
    
    func sendGameSettings(_ settings: GameSettings) {
        guard let session = session else { return }
        let settingsData = GameSettingsData(
            playerColor: settings.playerColor == .white ? "White" : "Black",
            timerMode: settings.timerMode.rawValue,
            timePerMove: Int(settings.timePerMove),
            initialWhiteTime: Int(settings.timePerMove),
            initialBlackTime: Int(settings.timePerMove)
        )
        let data = try? JSONEncoder().encode(["gameSettings": settingsData])
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
    }
    
    func sendBoardState(_ board: [[Piece?]], capturedWhite: Int, capturedBlack: Int) {
        guard let session = session else { return }
        var boardState: [[String]] = Array(repeating: Array(repeating: ".", count: 8), count: 8)
        
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col] {
                    let isKing = piece.isKing || piece.type == .king
                    boardState[row][col] = piece.color == .white ? (isKing ? "WK" : "W") : (isKing ? "BK" : "B")
                }
            }
        }
        
        let data = try? JSONEncoder().encode(BoardStateData(
            boardState: boardState,
            capturedWhite: capturedWhite,
            capturedBlack: capturedBlack
        ))
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
    }
    
    func sendCurrentPlayer(_ player: String) {
        guard let session = session else { return }
        let data = try? JSONEncoder().encode(["currentPlayer": player])
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
    }
    
    func connectToPeer(_ peer: MCPeerID) {
        browser?.invitePeer(peer, to: session!, withContext: nil, timeout: 30)
    }
    
    func connectToRandomRoom() {
        guard let randomPeer = session?.connectedPeers.randomElement() else {
            return
        }
        browser?.invitePeer(randomPeer, to: session!, withContext: nil, timeout: 30)
    }
}

extension GameSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.delegate?.didUpdateConnectedPeers(session.connectedPeers)
                self.delegate?.didUpdateConnectionStatus("Connected to \(peerID.displayName)")
                
            case .connecting:
                self.delegate?.didUpdateConnectionStatus("Connecting to \(peerID.displayName)...")
                
            case .notConnected:
                self.delegate?.didUpdateConnectedPeers(session.connectedPeers)
                self.delegate?.didUpdateConnectionStatus("Disconnected from \(peerID.displayName)")
                
            @unknown default:
                self.delegate?.didUpdateConnectionStatus("Unknown state for \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let playerData = try? JSONDecoder().decode([String: String].self, from: data),
           let player = playerData["currentPlayer"] {
            DispatchQueue.main.async {
                self.delegate?.didReceiveCurrentPlayer(player)
            }
        } else if let boardData = try? JSONDecoder().decode(BoardStateData.self, from: data) {
            DispatchQueue.main.async {
                self.delegate?.didReceiveBoardState(boardData.boardState, capturedWhite: boardData.capturedWhite, capturedBlack: boardData.capturedBlack)
            }
        } else if let boardData = try? JSONDecoder().decode([String: [[Piece?]]].self, from: data),
                  let board = boardData["initialBoard"] {
            DispatchQueue.main.async {
                self.delegate?.didReceiveInitialBoard(board)
            }
        } else if let settingsData = try? JSONDecoder().decode([String: GameSettingsData].self, from: data),
                  let settings = settingsData["gameSettings"] {
            DispatchQueue.main.async {
                let gameSettings = GameSettings(
                    playerColor: settings.playerColor == "White" ? .white : .black,
                    timerMode: TimerMode(rawValue: settings.timerMode) ?? .noLimit,
                    timePerMove: Double(settings.timePerMove),
                    boardStyle: UserDefaultsManager.shared.getSelectedBoardStyle()
                )
                self.delegate?.didReceiveGameSettings(gameSettings)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension GameSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension GameSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            var currentPeers = self.session?.connectedPeers ?? []
            if !currentPeers.contains(peerID) {
                currentPeers.append(peerID)
                self.delegate?.didUpdateAvailablePeers(currentPeers)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            var currentPeers = self.session?.connectedPeers ?? []
            currentPeers.removeAll { $0 == peerID }
            self.delegate?.didUpdateAvailablePeers(currentPeers)
        }
    }
}
