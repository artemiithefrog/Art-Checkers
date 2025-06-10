import Foundation
import MultipeerConnectivity

class GameRoom: NSObject, ObservableObject {
    @Published var isHost: Bool = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var statusMessage: String = ""
    @Published var gameSettings: GameSettings?
    
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let serviceType = "counter-game"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        statusMessage = "Session created"
    }
    
    func startHosting(settings: GameSettings) {
        isHost = true
        gameSettings = settings
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        statusMessage = "Waiting for connection..."
        print("Started advertising as host")
    }
    
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        statusMessage = "Searching for rooms..."
        print("Started browsing for peers")
    }
    
    func sendGameSettings(_ settings: GameSettings) {
        guard let session = session else { return }
        let data = try? JSONEncoder().encode(settings)
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
    }
}

extension GameRoom: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.statusMessage = "Connected to \(peerID.displayName)"
                    if self.isHost {
                        self.sendGameSettings(self.gameSettings!)
                    }
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.statusMessage = "Disconnected from \(peerID.displayName)"
            case .connecting:
                self.statusMessage = "Connecting to \(peerID.displayName)..."
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            DispatchQueue.main.async {
                self.gameSettings = settings
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
            self.statusMessage = "Received invitation from \(peerID.displayName)"
        }
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Error creating room: \(error.localizedDescription)"
        }
    }
}

extension GameRoom: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            self.statusMessage = "Found room: \(peerID.displayName)"
        }
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.statusMessage = "Room unavailable: \(peerID.displayName)"
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Error searching for rooms: \(error.localizedDescription)"
        }
    }
} 