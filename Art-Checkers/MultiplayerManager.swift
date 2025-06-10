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
        setupSession()
    }
    
    private func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        statusMessage = "Сессия создана"
    }
    
    func startHosting() {
        isHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        statusMessage = "Ожидание подключения..."
    }
    
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        statusMessage = "Поиск комнат..."
    }
    
    func disconnect() {
        session?.disconnect()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        connectedPeers.removeAll()
        statusMessage = "Отключено"
    }
}

// MARK: - MCSessionDelegate
extension MultiplayerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.statusMessage = "Подключено к \(peerID.displayName)"
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.statusMessage = "Отключено от \(peerID.displayName)"
            case .connecting:
                self.statusMessage = "Подключение к \(peerID.displayName)..."
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {

    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultiplayerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.statusMessage = "Получено приглашение от \(peerID.displayName)"
        }
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Ошибка создания комнаты: \(error.localizedDescription)"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultiplayerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            self.statusMessage = "Найдена комната: \(peerID.displayName)"
        }
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.statusMessage = "Комната недоступна: \(peerID.displayName)"
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Ошибка поиска комнат: \(error.localizedDescription)"
        }
    }
} 
