import Foundation
import MultipeerConnectivity

class GameRoom: NSObject, ObservableObject {
    static let shared = GameRoom()
    
    @Published var isHost: Bool = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var foundPeers: [MCPeerID] = []
    @Published var statusMessage: String = ""
    @Published var gameSettings: GameSettings?
    @Published var isSearching: Bool = false
    
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let serviceType = "checkers-game"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    private override init() {
        super.init()
        print("🎮 GameRoom: Initializing game room")
        setupSession()
    }
    
    deinit {
        print("🎮 GameRoom: Deinitializing game room")
        cleanup()
    }
    
    private func setupSession() {
        print("🎮 GameRoom: Setting up MultipeerConnectivity session")
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        statusMessage = "Ready"
        print("🎮 GameRoom: Session setup complete")
    }
    
    func startHosting(settings: GameSettings) {
        print("🎮 GameRoom: Starting to host game room")
        print("🎮 GameRoom: Game settings:")
        print("  - Player Color: \(settings.playerColor)")
        print("  - Timer Mode: \(settings.timerMode)")
        print("  - Time Per Move: \(settings.timePerMove)")
        print("  - Board Style: \(settings.boardStyle)")
        
        cleanup()
        
        isHost = true
        gameSettings = settings
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        print("🎮 GameRoom: Started advertising peer")
        statusMessage = "Room created"
    }
    
    func startBrowsing() {
        print("🎮 GameRoom: Starting to browse for game rooms")
        cleanup()
        
        isSearching = true
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self, self.isSearching else { return }
            self.browser?.stopBrowsingForPeers()
            self.browser?.startBrowsingForPeers()
        }
        
        print("🎮 GameRoom: Started browsing for peers")
        statusMessage = "Searching..."
    }
    
    func stopBrowsing() {
        print("🎮 GameRoom: Stopping room search")
        browser?.stopBrowsingForPeers()
        browser = nil
        isSearching = false
        statusMessage = "Search stopped"
    }
    
    func disconnect() {
        print("🎮 GameRoom: Disconnecting from current session")
        cleanup()
        statusMessage = "Disconnected"
    }
    
    private func cleanup() {
        if isHost {
            print("🎮 GameRoom: Stopping advertising as host")
            advertiser?.stopAdvertisingPeer()
            advertiser = nil
            isHost = false
        }
        
        if isSearching {
            stopBrowsing()
        }
        
        session?.disconnect()
        connectedPeers.removeAll()
        foundPeers.removeAll()
        print("🎮 GameRoom: Cleanup complete")
    }
    
    private func sendGameSettings() {
        guard let session = session, let settings = gameSettings else { return }
        print("🎮 GameRoom: Sending game settings to peers")
        let data = try? JSONEncoder().encode(settings)
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
        print("🎮 GameRoom: Game settings sent successfully")
    }
}

// MARK: - MCSessionDelegate
extension GameRoom: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    print("🎮 GameRoom: Peer connected: \(peerID.displayName)")
                    self.connectedPeers.append(peerID)
                    self.foundPeers.removeAll { $0 == peerID }
                    self.statusMessage = "Connected to \(peerID.displayName)"
                    if self.isHost {
                        print("🎮 GameRoom: Sending game settings to new peer")
                        self.sendGameSettings()
                    }
                }
            case .notConnected:
                print("🎮 GameRoom: Peer disconnected: \(peerID.displayName)")
                self.connectedPeers.removeAll { $0 == peerID }
                self.statusMessage = "Disconnected from \(peerID.displayName)"
            case .connecting:
                print("🎮 GameRoom: Connecting to peer: \(peerID.displayName)")
                self.statusMessage = "Connecting to \(peerID.displayName)..."
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            print("🎮 GameRoom: Received game settings from peer: \(peerID.displayName)")
            print("🎮 GameRoom: Received settings:")
            print("  - Player Color: \(settings.playerColor)")
            print("  - Timer Mode: \(settings.timerMode)")
            print("  - Time Per Move: \(settings.timePerMove)")
            print("  - Board Style: \(settings.boardStyle)")
            
            DispatchQueue.main.async {
                self.gameSettings = settings
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension GameRoom: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("🎮 GameRoom: Received invitation from peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Received invitation from \(peerID.displayName)"
        }
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("🎮 GameRoom: Error creating room: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.statusMessage = "Error creating room: \(error.localizedDescription)"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension GameRoom: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🎮 GameRoom: Found room: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Found room: \(peerID.displayName)"
            if !self.foundPeers.contains(peerID) {
                self.foundPeers.append(peerID)
            }
        }
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("🎮 GameRoom: Room unavailable: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Room unavailable: \(peerID.displayName)"
            self.foundPeers.removeAll { $0 == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("🎮 GameRoom: Error searching for rooms: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.statusMessage = "Error searching for rooms: \(error.localizedDescription)"
            self.isSearching = false
        }
    }
} 

