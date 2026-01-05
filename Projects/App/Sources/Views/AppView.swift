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
                    TrackpadView(store: store.scope(state: \.trackpad, action: \.trackpad))
                        .tag(AppFeature.Tab.trackpad)
                        .tabItem {
                            Label(
                                AppFeature.Tab.trackpad.title,
                                systemImage: AppFeature.Tab.trackpad.icon
                            )
                        }

                    KeyboardView(store: store.scope(state: \.keyboard, action: \.keyboard))
                        .tag(AppFeature.Tab.keyboard)
                        .tabItem {
                            Label(
                                AppFeature.Tab.keyboard.title,
                                systemImage: AppFeature.Tab.keyboard.icon
                            )
                        }

                    MediaView(store: store.scope(state: \.media, action: \.media))
                        .tag(AppFeature.Tab.media)
                        .tabItem {
                            Label(
                                AppFeature.Tab.media.title,
                                systemImage: AppFeature.Tab.media.icon
                            )
                        }

                    ProductivityView(store: store.scope(state: \.productivity, action: \.productivity))
                        .tag(AppFeature.Tab.productivity)
                        .tabItem {
                            Label(
                                AppFeature.Tab.productivity.title,
                                systemImage: AppFeature.Tab.productivity.icon
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
            SettingsView(store: store.scope(state: \.settings, action: \.settings)) {
                store.send(.hideSettings)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.connection.isPairingRequired },
                set: { if !$0 { store.send(.connection(.cancelPairing)) } }
            )
        ) {
            PairingPinView(
                serverName: store.connection.pairingServerName,
                pinCode: Binding(
                    get: { store.connection.pairingPinCode },
                    set: { store.send(.connection(.pairingPinCodeChanged($0))) }
                ),
                onSubmit: { store.send(.connection(.submitPairingPin)) },
                onCancel: { store.send(.connection(.cancelPairing)) }
            )
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

// MARK: - Pairing PIN View

struct PairingPinView: View {
    let serverName: String
    @Binding var pinCode: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.shield")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Enter PIN Code")
                        .font(.title2.weight(.bold))

                    Text("Enter the 4-digit PIN shown on\n\(serverName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // PIN Input
                VStack(spacing: 16) {
                    // Hidden text field
                    TextField("", text: $pinCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isTextFieldFocused)
                        .opacity(0)
                        .frame(width: 1, height: 1)

                    // PIN Display
                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            pinDigitView(at: index)
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = true
                    }
                }

                Spacer()

                // Submit Button
                Button {
                    onSubmit()
                } label: {
                    Text("Connect")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(pinCode.count == 4 ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(pinCode.count != 4)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Pairing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private func pinDigitView(at index: Int) -> some View {
        let digit = pinCode.count > index ? String(pinCode[pinCode.index(pinCode.startIndex, offsetBy: index)]) : ""
        let isFilled = !digit.isEmpty

        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFilled ? Color.blue : Color(.separator), lineWidth: 2)
                .frame(width: 56, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )

            if isFilled {
                Text(digit)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(.label))
            } else {
                Circle()
                    .fill(Color(.tertiaryLabel))
                    .frame(width: 12, height: 12)
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
