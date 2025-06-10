import SwiftUI

struct ConnectedPlayerView: View {
    @ObservedObject var multiplayerManager: MultiplayerManager
    
    var body: some View {
        VStack {
            Text("Подключено к игре")
                .font(.title)
                .padding()
            
            Text(multiplayerManager.statusMessage)
                .foregroundColor(.gray)
                .padding()
            
            Text("Всего шашек на доске:")
                .font(.headline)
                .padding(.top)
            
            Text("\(multiplayerManager.totalPieces)")
                .font(.system(size: 60, weight: .bold))
                .padding()
            
            Button(action: {
                multiplayerManager.disconnect()
            }) {
                Text("Отключиться")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
} 