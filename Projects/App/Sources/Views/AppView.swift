import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection Status Bar
                ConnectionStatusBar(status: store.connection.status, signalStrength: store.connection.signalStrength)

                // Main Content
                TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
                    EssentialsTabView()
                        .tag(AppFeature.Tab.essentials)
                        .tabItem {
                            Label(
                                AppFeature.Tab.essentials.title,
                                systemImage: AppFeature.Tab.essentials.icon
                            )
                        }

                    ProductivityTabView()
                        .tag(AppFeature.Tab.productivity)
                        .tabItem {
                            Label(
                                AppFeature.Tab.productivity.title,
                                systemImage: AppFeature.Tab.productivity.icon
                            )
                        }

                    PresenterTabView()
                        .tag(AppFeature.Tab.presenter)
                        .tabItem {
                            Label(
                                AppFeature.Tab.presenter.title,
                                systemImage: AppFeature.Tab.presenter.icon
                            )
                        }
                }
            }
            .navigationTitle("Snap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.showConnectionSheet)
                    } label: {
                        connectionIcon
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.showSettings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.isConnectionSheetPresented },
                set: { if !$0 { store.send(.hideConnectionSheet) } }
            )
        ) {
            ConnectionSheetView {
                store.send(.hideConnectionSheet)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.isSettingsPresented },
                set: { if !$0 { store.send(.hideSettings) } }
            )
        ) {
            SettingsSheetView(store: store.scope(state: \.settings, action: \.settings)) {
                store.send(.hideSettings)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    @ViewBuilder
    private var connectionIcon: some View {
        switch store.connection.status {
        case .disconnected:
            Image(systemName: "wifi.slash")
                .foregroundStyle(.secondary)
        case .discovering:
            Image(systemName: "wifi")
                .foregroundStyle(.orange)
        case .connecting:
            Image(systemName: "wifi")
                .foregroundStyle(.yellow)
        case .connected:
            Image(systemName: "wifi")
                .foregroundStyle(.green)
        case .reconnecting:
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(.orange)
        }
    }
}

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    let status: ConnectionStatus
    let signalStrength: SignalStrength

    var body: some View {
        HStack {
            statusIcon
            statusText
            Spacer()
            if status.isConnected {
                signalIndicator
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .disconnected:
            Image(systemName: "wifi.slash")
                .foregroundStyle(.secondary)
        case .discovering, .connecting:
            ProgressView()
                .scaleEffect(0.8)
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .reconnecting:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(.orange)
        }
    }

    private var statusText: some View {
        Text(statusMessage)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var statusMessage: String {
        switch status {
        case .disconnected:
            return "Not Connected"
        case .discovering:
            return "Searching..."
        case .connecting(let device):
            return "Connecting to \(device.name)..."
        case .connected(let device):
            return "Connected to \(device.name)"
        case .reconnecting(_, let attempt):
            return "Reconnecting... (\(attempt)/3)"
        }
    }

    @ViewBuilder
    private var signalIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(signalColor(for: index))
                    .frame(width: 3, height: CGFloat(4 + index * 3))
            }
        }
    }

    private func signalColor(for index: Int) -> Color {
        switch signalStrength {
        case .strong:
            return .green
        case .moderate:
            return index < 2 ? .yellow : .secondary.opacity(0.3)
        case .weak:
            return index < 1 ? .red : .secondary.opacity(0.3)
        case .unknown:
            return .secondary.opacity(0.3)
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .disconnected:
            return .secondary.opacity(0.1)
        case .discovering, .connecting:
            return .orange.opacity(0.1)
        case .connected:
            return .green.opacity(0.1)
        case .reconnecting:
            return .orange.opacity(0.1)
        }
    }
}

// MARK: - Tab Placeholder Views

struct EssentialsTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.tap")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Essentials")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Trackpad, Keyboard, Media Controls")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ProductivityTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundStyle(.purple)

            Text("Productivity")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Window Snap, App Switcher, Macros")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct PresenterTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.wave.2")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Presenter")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Laser Pointer, Slides, Voice Typing")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Sheet Views

struct ConnectionSheetView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "wifi")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Connect to Mac")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Make sure your Mac is running Snap Receiver")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                ProgressView("Searching for devices...")

                Spacer()
            }
            .padding()
            .navigationTitle("Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct SettingsSheetView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Trackpad") {
                    VStack(alignment: .leading) {
                        Text("Sensitivity: \(store.trackpadSensitivity, specifier: "%.1f")")
                        Slider(value: $store.trackpadSensitivity.sending(\.setTrackpadSensitivity), in: 0.5...2.0)
                    }

                    VStack(alignment: .leading) {
                        Text("Scroll Sensitivity: \(store.scrollSensitivity, specifier: "%.1f")")
                        Slider(value: $store.scrollSensitivity.sending(\.setScrollSensitivity), in: 0.5...2.0)
                    }

                    Toggle("Natural Scrolling", isOn: Binding(
                        get: { store.isNaturalScrolling },
                        set: { _ in store.send(.toggleNaturalScrolling) }
                    ))
                    Toggle("Tap to Click", isOn: Binding(
                        get: { store.isTapToClick },
                        set: { _ in store.send(.toggleTapToClick) }
                    ))
                }

                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { store.isHapticEnabled },
                        set: { _ in store.send(.toggleHaptic) }
                    ))
                }

                Section {
                    Button("Reset to Defaults") {
                        store.send(.resetToDefaults)
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
