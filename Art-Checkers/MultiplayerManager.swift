import Foundation
import MultipeerConnectivity
import SwiftUI

class MultiplayerManager: NSObject, ObservableObject {
    @Published var connectedPeers: [MCPeerID] = []
    @Published var statusMessage: String = ""
    @Published var isHost: Bool = false
    @Published var totalPieces: Int = 24
    
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let serviceType = "art-checkers"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    override init() {
        super.init()
        print("🎮 MultiplayerManager: Initializing multiplayer manager")
        setupSession()
    }
    
    private func setupSession() {
        print("🎮 MultiplayerManager: Setting up MultipeerConnectivity session")
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        statusMessage = "Сессия создана"
        print("🎮 MultiplayerManager: Session setup complete")
    }
    
    func startHosting() {
        print("🎮 MultiplayerManager: Starting to host game room")
        isHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("🎮 MultiplayerManager: Started advertising peer")
        statusMessage = "Ожидание подключения..."
    }
    
    func startBrowsing() {
        print("🎮 MultiplayerManager: Starting to browse for game rooms")
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("🎮 MultiplayerManager: Started browsing for peers")
        statusMessage = "Поиск комнат..."
    }
    
    func disconnect() {
        print("🎮 MultiplayerManager: Disconnecting from current session")
        session?.disconnect()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        connectedPeers.removeAll()
        statusMessage = "Отключено"
        print("🎮 MultiplayerManager: Disconnection complete")
    }
}

// MARK: - MCSessionDelegate
extension MultiplayerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("🎮 MultiplayerManager: Peer connected: \(peerID.displayName)")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.statusMessage = "Подключено к \(peerID.displayName)"
                }
            case .notConnected:
                print("🎮 MultiplayerManager: Peer disconnected: \(peerID.displayName)")
                self.connectedPeers.removeAll { $0 == peerID }
                self.statusMessage = "Отключено от \(peerID.displayName)"
            case .connecting:
                print("🎮 MultiplayerManager: Connecting to peer: \(peerID.displayName)")
                self.statusMessage = "Подключение к \(peerID.displayName)..."
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("🎮 MultiplayerManager: Received data from peer: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("🎮 MultiplayerManager: Received stream from peer: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("🎮 MultiplayerManager: Started receiving resource from peer: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            print("🎮 MultiplayerManager: Error receiving resource from peer \(peerID.displayName): \(error.localizedDescription)")
        } else {
            print("🎮 MultiplayerManager: Successfully received resource from peer: \(peerID.displayName)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultiplayerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("🎮 MultiplayerManager: Received invitation from peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Получено приглашение от \(peerID.displayName)"
        }
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("🎮 MultiplayerManager: Error creating room: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.statusMessage = "Ошибка создания комнаты: \(error.localizedDescription)"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultiplayerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🎮 MultiplayerManager: Found room: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Найдена комната: \(peerID.displayName)"
        }
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("🎮 MultiplayerManager: Room unavailable: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Комната недоступна: \(peerID.displayName)"
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("🎮 MultiplayerManager: Error searching for rooms: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.statusMessage = "Ошибка поиска комнат: \(error.localizedDescription)"
        }
    }
} 
