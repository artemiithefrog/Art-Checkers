import SwiftUI

struct ConnectionView: View {
    @StateObject private var multiplayerManager = MultiplayerManager()
    
    var body: some View {
        VStack {
            if multiplayerManager.connectedPeers.isEmpty {
                connectionOptionsView
            } else {
                ConnectedPlayerView(multiplayerManager: multiplayerManager)
            }
        }
        .padding()
    }
    
    private var connectionOptionsView: some View {
        VStack(spacing: 20) {
            Text("Шашки")
                .font(.largeTitle)
                .bold()
            
            Text(multiplayerManager.statusMessage)
                .foregroundColor(.gray)
                .padding()
            
            Button(action: {
                multiplayerManager.startHosting()
            }) {
                Text("Создать комнату")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                multiplayerManager.startBrowsing()
            }) {
                Text("Найти комнату")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
} 