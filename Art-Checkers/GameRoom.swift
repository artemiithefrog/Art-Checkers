import Foundation
import MultipeerConnectivity

class GameRoom: NSObject, ObservableObject {
    @Published var isHost: Bool = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var statusMessage: String = ""
    @Published var gameSettings: GameSettings?
    @Published var isSearching: Bool = false
    
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let serviceType = "counter-game"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    override init() {
        super.init()
        print("🎮 GameRoom: Initializing with peer ID: \(myPeerId.displayName)")
        setupSession()
    }
    
    private func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        print("🎮 GameRoom: Session created with peer: \(myPeerId.displayName)")
        statusMessage = "Session created"
    }
    
    func startHosting(settings: GameSettings) {
        print("🎮 GameRoom: Starting to host game room")
        isHost = true
        gameSettings = settings
        
        guard let session = session else {
            print("❌ GameRoom: Cannot start hosting - session is nil")
            return
        }

        let discoveryInfo = ["gameType": "checkers"]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self

        guard let advertiser = advertiser else {
            print("❌ GameRoom: Failed to create advertiser")
            return
        }
        
        print("🎮 GameRoom: Starting advertising with service type: \(serviceType)")
        advertiser.startAdvertisingPeer()
        print("🎮 GameRoom: Room is now discoverable by other devices")
        statusMessage = "Waiting for connection..."
    }
    
    func startBrowsing() {
        print("🎮 GameRoom: Starting to browse for game rooms")
        isSearching = true

        guard let session = session else {
            print("❌ GameRoom: Cannot start browsing - session is nil")
            isSearching = false
            return
        }

        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        
        guard let browser = browser else {
            print("❌ GameRoom: Failed to create browser")
            isSearching = false
            return
        }
        
        print("🎮 GameRoom: Starting browsing with service type: \(serviceType)")
        browser.startBrowsingForPeers()
        statusMessage = "Searching for rooms..."
    }
    
    func stopBrowsing() {
        print("🎮 GameRoom: Stopping room search")
        browser?.stopBrowsingForPeers()
        isSearching = false
        statusMessage = "Search stopped"
    }
    
    func sendGameSettings(_ settings: GameSettings) {
        guard let session = session else {
            print("❌ GameRoom: Failed to send game settings - session is nil")
            return
        }
        print("🎮 GameRoom: Sending game settings to \(session.connectedPeers.count) peers")
        let data = try? JSONEncoder().encode(settings)
        try? session.send(data ?? Data(), toPeers: session.connectedPeers, with: .reliable)
    }
}

extension GameRoom: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ GameRoom: Connected to peer: \(peerID.displayName)")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.statusMessage = "Connected to \(peerID.displayName)"
                    if self.isHost {
                        print("🎮 GameRoom: Sending game settings to new peer: \(peerID.displayName)")
                        self.sendGameSettings(self.gameSettings!)
                    }
                }
            case .notConnected:
                print("❌ GameRoom: Disconnected from peer: \(peerID.displayName)")
                self.connectedPeers.removeAll { $0 == peerID }
                self.statusMessage = "Disconnected from \(peerID.displayName)"
            case .connecting:
                print("🔄 GameRoom: Connecting to peer: \(peerID.displayName)")
                self.statusMessage = "Connecting to \(peerID.displayName)..."
            @unknown default:
                print("⚠️ GameRoom: Unknown connection state for peer: \(peerID.displayName)")
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("📥 GameRoom: Received data from peer: \(peerID.displayName)")
        if let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            print("✅ GameRoom: Successfully decoded game settings from peer: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.gameSettings = settings
            }
        } else {
            print("❌ GameRoom: Failed to decode game settings from peer: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("📥 GameRoom: Received stream '\(streamName)' from peer: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("📥 GameRoom: Started receiving resource '\(resourceName)' from peer: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            print("❌ GameRoom: Error receiving resource '\(resourceName)' from peer: \(peerID.displayName) - \(error.localizedDescription)")
        } else {
            print("✅ GameRoom: Successfully received resource '\(resourceName)' from peer: \(peerID.displayName)")
        }
    }
}

extension GameRoom: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📨 GameRoom: Received invitation from peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Received invitation from \(peerID.displayName)"
        }
        invitationHandler(true, session)
        print("✅ GameRoom: Accepted invitation from peer: \(peerID.displayName)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ GameRoom: Failed to start advertising - \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.statusMessage = "Error creating room: \(error.localizedDescription)"
        }
    }
}

extension GameRoom: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 GameRoom: Found peer: \(peerID.displayName)")
        print("🔍 GameRoom: Discovery info: \(info ?? [:])")
        
        DispatchQueue.main.async {
            self.statusMessage = "Found room: \(peerID.displayName)"
            self.isSearching = false
        }

        guard let session = session else {
            print("❌ GameRoom: Cannot invite peer - session is nil")
            return
        }
        
        print("📨 GameRoom: Sending invitation to peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("❌ GameRoom: Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.statusMessage = "Room unavailable: \(peerID.displayName)"
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ GameRoom: Failed to start browsing - \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.statusMessage = "Error searching for rooms: \(error.localizedDescription)"
            self.isSearching = false
        }
    }
} 
