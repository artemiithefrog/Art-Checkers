//
//  ConnectToRoomView.swift
//  Art-Checkers
//
//  Created by artemiithefrog on 12.06.2025.
//

import SwiftUI

struct ConnectToRoomView: View {
    @EnvironmentObject var gameRoom: GameRoom
    @Environment(\.dismiss) var dismiss
    @Binding var showGame: Bool
    @State private var isSearching = false
    @State private var isConnecting = false
    @State private var connectingToPeer: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    gameRoom.cleanup()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Available Rooms")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    isSearching = true
                    gameRoom.startBrowsing()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top)

            if isSearching && gameRoom.availablePeers.isEmpty {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.gray)
                    
                    Text("Searching for rooms...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else if gameRoom.availablePeers.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No rooms available")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button {
                        isSearching = true
                        gameRoom.startBrowsing()
                    } label: {
                        Text("Refresh")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.3, green: 0.8, blue: 0.6),
                                        Color(red: 0.3, green: 0.8, blue: 0.6).opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Button {
                        isConnecting = true
                        gameRoom.connectToRandomRoom()
                    } label: {
                        HStack {
                            if isConnecting && connectingToPeer == nil {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "dice.fill")
                                    .font(.system(size: 18))
                            }
                            Text("Connect to Random Room")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.6, blue: 0.9),
                                    Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isConnecting)
                    .padding(.top, 8)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(gameRoom.availablePeers, id: \.self) { peer in
                                RoomCell(peer: peer.displayName, isConnecting: isConnecting && connectingToPeer == peer.displayName) {
                                    isConnecting = true
                                    connectingToPeer = peer.displayName
                                    gameRoom.connectToPeer(peer)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            isSearching = true
            gameRoom.startBrowsing()
        }
        .onDisappear {
            if !showGame {
                gameRoom.cleanup()
            }
        }
        .onChange(of: gameRoom.availablePeers) { peers in
            if !peers.isEmpty {
                isSearching = false
            }
        }
        .onChange(of: gameRoom.connectedPeers.isEmpty) { isEmpty in
            if !isEmpty {
                showGame = true
            }
        }
    }
}
