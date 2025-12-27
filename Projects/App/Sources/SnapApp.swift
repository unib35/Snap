import SwiftUI
import ComposableArchitecture

@main
struct SnapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Snap")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("iOS Remote Controller")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
