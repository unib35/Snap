import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    private var isConnected: Bool {
        if case .connected = store.connection.status { return true }
        return false
    }

    private var connectionTitle: String {
        switch store.connection.status {
        case .connected(let device): return device.name
        case .disconnected: return "Mac 연결"
        case .discovering: return "Mac 검색 중"
        case .connecting: return "연결 중"
        case .reconnecting: return "다시 연결 중"
        }
    }

    private var connectionAccessibilityLabel: String {
        switch store.connection.status {
        case .disconnected:
            return String(localized: "connection.disconnected")
        case .discovering:
            return String(localized: "connection.discovering")
        case .connecting(let device):
            return String(localized: "connection.connecting \(device.name)")
        case .connected(let device):
            return String(localized: "connection.connected \(device.name)")
        case .reconnecting(_, let attempt):
            return String(localized: "connection.reconnecting \(attempt)")
        }
    }

    public var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            remoteTab(.trackpad) {
                TrackpadView(store: store.scope(state: \.trackpad, action: \.trackpad))
            }
            remoteTab(.keyboard) {
                KeyboardView(store: store.scope(state: \.keyboard, action: \.keyboard))
            }
            remoteTab(.media) {
                MediaView(store: store.scope(state: \.media, action: \.media))
            }
            remoteTab(.productivity) {
                ProductivityView(store: store.scope(state: \.productivity, action: \.productivity))
            }
        }
        .adaptiveLayout()
        .sheet(
            isPresented: Binding(
                get: { store.isConnectionSheetPresented },
                set: { if !$0 { store.send(.hideConnectionSheet) } }
            )
        ) {
            ConnectionSheetView(store: store.scope(state: \.connection, action: \.connection)) {
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
            PairingCodeView(
                serverName: store.connection.pairingServerName,
                errorMessage: store.connection.lastError?.localizedDescription,
                onCode: { store.send(.connection(.pairingCodeScanned($0))) },
                onCancel: { store.send(.connection(.cancelPairing)) }
            )
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.isOnboardingPresented },
                set: { if !$0 { store.send(.hideOnboarding) } }
            )
        ) {
            OnboardingView(
                store: store.scope(state: \.onboarding, action: \.onboarding)
            ) {
                store.send(.completeOnboarding)
            }
        }
        .onAppear {
            store.send(.onAppear)
            store.send(.settings(.onAppear))
        }
        .tint(store.settings.accentColor.color)
        .accentColor(store.settings.accentColor.color)
        .reducedAnimations(store.settings.isInPowerSavingMode && store.settings.reducedAnimations)
    }

    private func remoteTab<Content: View>(
        _ tab: AppFeature.Tab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            Group {
                if isConnected {
                    content()
                } else {
                    connectionPrompt
                }
            }
            .errorBanner(
                store.connection.lastError,
                onDismiss: { store.send(.connection(.clearError)) },
                onRetry: { store.send(.connection(.retryAfterError)) }
            )
            .navigationTitle(tab.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { store.send(.showConnectionSheet) } label: {
                        HStack(spacing: 6) {
                            connectionIcon
                            Text(connectionTitle)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 100)
                        }
                    }
                    .accessibilityLabel(connectionAccessibilityLabel)
                    .accessibilityHint(String(localized: "connection.hint"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.showSettings) } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(String(localized: "settings"))
                }
            }
            .toolbarBackground(SnapColors.background, for: .navigationBar)
        }
        .tag(tab)
        .tabItem { Label(tab.title, systemImage: tab.icon) }
    }

    private var connectionPrompt: some View {
        ContentUnavailableView {
            Label(isConnectionPending ? "Mac에 연결하고 있어요" : "Mac을 연결해 시작하세요", systemImage: "desktopcomputer")
        } description: {
            Text(isConnectionPending
                 ? "연결이 완료되면 바로 조작할 수 있습니다."
                 : "Mac에서 Snap Receiver를 실행하고, 같은 Wi-Fi에 연결하세요.")
        } actions: {
            if isConnectionPending {
                ProgressView().padding(.bottom, 8)
            }
            Button(isConnectionPending ? "연결 상태 보기" : "Mac 찾기") {
                store.send(.showConnectionSheet)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SnapColors.background)
    }

    private var isConnectionPending: Bool {
        switch store.connection.status {
        case .connecting, .reconnecting: return true
        case .disconnected, .discovering, .connected: return false
        }
    }

    @ViewBuilder
    private var connectionIcon: some View {
        switch store.connection.status {
        case .disconnected:
            Image(systemName: "wifi.slash")
                .foregroundStyle(SnapColors.statusDisconnected)
        case .discovering:
            Image(systemName: "wifi")
                .foregroundStyle(SnapColors.statusDiscovering)
        case .connecting:
            Image(systemName: "wifi")
                .foregroundStyle(SnapColors.statusConnecting)
        case .connected:
            Image(systemName: "wifi")
                .foregroundStyle(SnapColors.statusConnected)
        case .reconnecting:
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(SnapColors.statusConnecting)
        }
    }
}

// MARK: - Connection Sheet

struct ConnectionSheetView: View {
    let store: StoreOf<ConnectionFeature>
    let onDismiss: () -> Void
    @State private var deviceToReset: Device?

    var body: some View {
        NavigationStack {
            List {
                if case .connected(let device) = store.status {
                    Section("연결된 Mac") {
                        Label(device.name, systemImage: "checkmark.circle.fill")
                        LabeledContent("응답 시간", value: store.latency.map { "\(Int(($0 * 1000).rounded()))ms" } ?? "측정 중")
                        Button("연결 해제", role: .destructive) { store.send(.disconnect) }
                    }
                } else if case .connecting(let device) = store.status {
                    Section {
                        HStack { ProgressView(); Text("\(device.name)에 연결 중") }
                        Button("연결 취소", role: .cancel) { store.send(.disconnect) }
                    }
                } else if case .reconnecting(let device, _) = store.status {
                    Section {
                        HStack { ProgressView(); Text("\(device.name)에 다시 연결 중") }
                        Button("재연결 중지", role: .cancel) { store.send(.disconnect) }
                    }
                } else {
                    availableDevices
                }
                if let error = store.lastError {
                    Section("연결 안내") {
                        Text(error.localizedDescription).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Mac 연결")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("완료", action: onDismiss) }
            }
            .confirmationDialog(
                "저장된 Mac 연결 정보를 삭제할까요?",
                isPresented: Binding(get: { deviceToReset != nil }, set: { if !$0 { deviceToReset = nil } }),
                titleVisibility: .visible
            ) {
                Button("삭제 후 다시 페어링", role: .destructive) {
                    if let device = deviceToReset {
                        store.send(.forgetAndPair(device))
                        deviceToReset = nil
                        onDismiss()
                    }
                }
            } message: {
                Text("삭제 후에는 직접 보고 있는 Mac의 QR 코드로 다시 확인해야 합니다.")
            }
            .onAppear { store.send(.startDiscovery) }
        }
    }

    private var availableDevices: some View {
        Group {
            Section("사용 가능한 Mac") {
                ForEach(store.discoveredDevices) { device in
                    HStack {
                        Button {
                            store.send(.connect(device))
                            onDismiss()
                        } label: {
                            Label(device.name, systemImage: "desktopcomputer")
                        }
                        Spacer()
                        Menu {
                            Button("연결 정보 삭제 후 다시 페어링", role: .destructive) { deviceToReset = device }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("\(device.name) 연결 옵션")
                    }
                }
                if store.status == .disconnected {
                    Button("Mac 다시 검색") { store.send(.startDiscovery) }
                } else if store.discoveredDevices.isEmpty {
                    HStack {
                        ProgressView()
                        Text("같은 네트워크의 Mac을 찾고 있습니다")
                    }
                }
            }
            Section {
                Text("Mac에서 Snap Receiver를 실행하세요. 처음 연결할 때 Mac에 표시된 QR 코드를 스캔합니다.")
                    .foregroundStyle(.secondary)
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
