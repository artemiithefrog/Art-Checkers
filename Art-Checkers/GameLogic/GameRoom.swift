//
//  GameRoom.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 11.06.2025.
//

import Foundation
import MultipeerConnectivity

class GameRoom: NSObject, ObservableObject {
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
    
    private struct BoardStateData: Codable {
        let boardState: [[String]]
        let capturedWhite: Int
        let capturedBlack: Int
    }
    
    private struct GameSettingsData: Codable {
        let playerColor: String
        let timerMode: String
        let timePerMove: Int
        let initialWhiteTime: Int
        let initialBlackTime: Int
    }
    
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let serviceType = "checkers-game"
    private let peerID: MCPeerID
    
    override init() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        print("GameRoom: Инициализация GameRoom")
        setupSession()
        setupInitialBoardState()
    }
    
    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        statusMessage = "Сессия создана"
        print("GameRoom: Сессия создана для \(peerID.displayName)")
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
        print("GameRoom: Очистка состояния")

        for peer in connectedPeers {
            session?.cancelConnectPeer(peer)
        }

        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()

        connectedPeers.removeAll()
        availablePeers.removeAll()
                isHost = false
        currentSettings = nil
        
        setupSession()
    }
    
    func startHosting(settings: GameSettings) {
        cleanup()
        
        isHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        currentSettings = settings

        if let peer = connectedPeers.first {
            sendGameSettings(settings)
        }
    }
    
    func startBrowsing() {
        cleanup()
        
        print("GameRoom: Начало поиска комнат")
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        statusMessage = "Поиск комнат..."
        print("GameRoom: Начало поиска комнат")
        print("GameRoom: Ищу сервис типа: \(serviceType)")
    }
    
    func sendInitialBoard(_ board: [[Piece?]]) {
        guard let session = session else { return }
        let boardData = try? JSONEncoder().encode(["initialBoard": board])
        try? session.send(boardData ?? Data(), toPeers: session.connectedPeers, with: .reliable)
        print("GameRoom: Отправлено начальное положение шашек")
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
        print("GameRoom: Отправлены настройки игры")
    }
    
    func sendBoardState(_ board: [[Piece?]]) {
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
            capturedWhite: capturedWhitePieces,
            capturedBlack: capturedBlackPieces
        ))
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
    }
    
    func playerChanged(currentPlayer: String) {
        self.currentPlayer = currentPlayer
        sendCounterUpdate()
    }
    
    private func sendCounterUpdate() {
        guard let session = session else { return }
        let data = try? JSONEncoder().encode(["currentPlayer": currentPlayer])
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
        print("GameRoom: Отправлено обновление цвета: \(currentPlayer)")
    }
    
    func connectToPeer(_ peer: MCPeerID) {
        print("GameRoom: Отправка приглашения к \(peer.displayName)")
        browser?.invitePeer(peer, to: session!, withContext: nil, timeout: 30)
    }
    
    func connectToRandomRoom() {
        guard let randomPeer = availablePeers.randomElement() else {
            print("GameRoom: Нет доступных комнат для подключения")
            return
        }
        
        print("GameRoom: Подключение к случайной комнате: \(randomPeer.displayName)")
        browser?.invitePeer(randomPeer, to: session!, withContext: nil, timeout: 30)
    }
}

extension GameRoom: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connected:
                print("GameRoom: Успешное подключение к \(peerID.displayName)")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                if self.availablePeers.contains(peerID) {
                    self.availablePeers.removeAll { $0 == peerID }
                }

                if self.isHost, let settings = self.currentSettings {
                    self.sendGameSettings(settings)
                }
                
            case .connecting:
                print("GameRoom: Подключение к \(peerID.displayName)...")
                
            case .notConnected:
                print("GameRoom: Отключено от \(peerID.displayName)")
                self.connectedPeers.removeAll { $0 == peerID }

                if !self.isHost && !self.availablePeers.contains(peerID) {
                    self.availablePeers.append(peerID)
                }
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let playerData = try? JSONDecoder().decode([String: String].self, from: data),
           let player = playerData["currentPlayer"] {
            DispatchQueue.main.async {
                self.currentPlayer = player
                print("GameRoom: Получено обновление цвета от \(peerID.displayName) - \(player)")
            }
        } else if let boardData = try? JSONDecoder().decode(BoardStateData.self, from: data) {
            DispatchQueue.main.async {
                self.boardState = boardData.boardState
                self.capturedWhitePieces = boardData.capturedWhite
                self.capturedBlackPieces = boardData.capturedBlack
                print("GameRoom: Получено обновление доски от \(peerID.displayName)")
                print("GameRoom: Захвачено белых шашек: \(boardData.capturedWhite)")
                print("GameRoom: Захвачено черных шашек: \(boardData.capturedBlack)")
                print("GameRoom: Текущее состояние доски:")
                for row in boardData.boardState {
                    print(row.joined(separator: " "))
                }
                print("")
            }
        } else if let boardData = try? JSONDecoder().decode([String: [[Piece?]]].self, from: data),
                  let board = boardData["initialBoard"] {
            DispatchQueue.main.async {
                self.initialBoard = board
                print("GameRoom: Получено начальное положение шашек от \(peerID.displayName)")
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
                self.currentSettings = gameSettings

                let timerValues = [
                    "initialWhiteTime": settings.initialWhiteTime,
                    "initialBlackTime": settings.initialBlackTime
                ]
                
                NotificationCenter.default.post(name: NSNotification.Name("GameSettingsReceived"), object: gameSettings)
                NotificationCenter.default.post(name: NSNotification.Name("TimerValuesReceived"), object: timerValues)
                
                print("GameRoom: Получены настройки игры от \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension GameRoom: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("GameRoom: Получено приглашение от \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("GameRoom: Ошибка создания комнаты: \(error.localizedDescription)")
    }
}

extension GameRoom: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("GameRoom: Найдена комната: \(peerID.displayName)")
        if !availablePeers.contains(peerID) {
            availablePeers.append(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("GameRoom: Потеряна комната: \(peerID.displayName)")
        availablePeers.removeAll { $0 == peerID }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("GameRoom: Ошибка поиска комнат: \(error.localizedDescription)")
    }
}
