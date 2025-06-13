//
//  GameSessionManagerDelegate.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 13.06.2025.
//

import Foundation
import MultipeerConnectivity

protocol GameSessionManagerDelegate: AnyObject {
    func didReceiveBoardState(_ boardState: [[String]], capturedWhite: Int, capturedBlack: Int)
    func didReceiveInitialBoard(_ board: [[Piece?]])
    func didReceiveGameSettings(_ settings: GameSettings)
    func didReceiveCurrentPlayer(_ player: String)
    func didUpdateConnectionStatus(_ status: String)
    func didUpdateConnectedPeers(_ peers: [MCPeerID])
    func didUpdateAvailablePeers(_ peers: [MCPeerID])
}
