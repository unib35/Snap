import SwiftUI

@main
struct MacReceiverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Snap Receiver")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Waiting for connection...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}

#Preview {
    ContentView()
}
