//
//  GameRoom.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 11.06.2025.
//

import Foundation
import MultipeerConnectivity

class GameRoom: NSObject, ObservableObject {
    @Published var counter1: Int = 0
    @Published var counter2: Int = 0
    @Published var currentPlayer = "White"
    @Published var isHost: Bool = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var statusMessage: String = ""
    
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let serviceType = "checkers-game"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    override init() {
        super.init()
        print("GameRoom: Инициализация GameRoom")
        setupSession()
    }
    
    private func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        statusMessage = "Сессия создана"
        print("GameRoom: Сессия создана для \(myPeerId.displayName)")
    }
    
    func startHosting() {
        isHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        statusMessage = "Ожидание подключения..."
        print("GameRoom: Начало создания комнаты как хост")
        print("GameRoom: Рекламирую сервис типа: \(serviceType)")
    }
    
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        statusMessage = "Поиск комнат..."
        print("GameRoom: Начало поиска комнат")
        print("GameRoom: Ищу сервис типа: \(serviceType)")
    }
    
    func incrementCounter1() {
        counter1 += 1
        print("GameRoom: Увеличен счетчик 1 до \(counter1)")
        sendCounterUpdate()
    }
    
    func incrementCounter2() {
        counter2 += 1
        print("GameRoom: Увеличен счетчик 2 до \(counter2)")
        sendCounterUpdate()
    }
    
    func playerChanged(currentPlayer: String) {
        self.currentPlayer = currentPlayer
        sendCounterUpdate()
    }
    
    private func sendCounterUpdate() {
        guard let session = session else { return }
//        let data = try? JSONEncoder().encode(["counter1": counter1, "counter2": counter2])
        let data = try? JSONEncoder().encode(["currentPlayer": currentPlayer])
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
        print("GameRoom: Отправлено обновление цвета: \(currentPlayer)")
    }
}

extension GameRoom: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.statusMessage = "Подключено к \(peerID.displayName)"
                    print("GameRoom: Успешное подключение к \(peerID.displayName)")
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.statusMessage = "Отключено от \(peerID.displayName)"
                print("GameRoom: Отключено от \(peerID.displayName)")
            case .connecting:
                self.statusMessage = "Подключение к \(peerID.displayName)..."
                print("GameRoom: Подключение к \(peerID.displayName)...")
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
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension GameRoom: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.statusMessage = "Получено приглашение от \(peerID.displayName)"
            print("GameRoom: Получено приглашение от \(peerID.displayName)")
            print("GameRoom: Принимаю приглашение от \(peerID.displayName)")
        }
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Ошибка создания комнаты: \(error.localizedDescription)"
            print("GameRoom: Ошибка создания комнаты - \(error.localizedDescription)")
        }
    }
}

extension GameRoom: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            self.statusMessage = "Найдена комната: \(peerID.displayName)"
            print("GameRoom: Найдена комната - \(peerID.displayName)")
            print("GameRoom: Отправляю приглашение \(peerID.displayName)")
        }
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.statusMessage = "Комната недоступна: \(peerID.displayName)"
            print("GameRoom: Комната стала недоступна - \(peerID.displayName)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Ошибка поиска комнат: \(error.localizedDescription)"
            print("GameRoom: Ошибка поиска комнат - \(error.localizedDescription)")
        }
    }
}
