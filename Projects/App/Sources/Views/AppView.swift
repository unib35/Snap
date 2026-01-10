import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    private var isDisconnected: Bool {
        if case .disconnected = store.connection.status {
            return true
        }
        return false
    }

    private var connectionAccessibilityLabel: String {
        switch store.connection.status {
        case .disconnected:
            return "연결 끊김"
        case .discovering:
            return "기기 검색 중"
        case .connecting(let device):
            return "\(device.name)에 연결 중"
        case .connected(let device):
            return "\(device.name)에 연결됨"
        case .reconnecting(_, let attempt):
            return "재연결 시도 중 (\(attempt)회)"
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection Status Bar
                ConnectionStatusBar(status: store.connection.status, signalStrength: store.connection.signalStrength)

                // Main Content with connection blur
                TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
                    TrackpadView(store: store.scope(state: \.trackpad, action: \.trackpad))
                        .connectionBlur(isDisconnected: isDisconnected)
                        .tag(AppFeature.Tab.trackpad)
                        .tabItem {
                            Label(
                                AppFeature.Tab.trackpad.title,
                                systemImage: AppFeature.Tab.trackpad.icon
                            )
                        }

                    KeyboardView(store: store.scope(state: \.keyboard, action: \.keyboard))
                        .connectionBlur(isDisconnected: isDisconnected)
                        .tag(AppFeature.Tab.keyboard)
                        .tabItem {
                            Label(
                                AppFeature.Tab.keyboard.title,
                                systemImage: AppFeature.Tab.keyboard.icon
                            )
                        }

                    MediaView(store: store.scope(state: \.media, action: \.media))
                        .connectionBlur(isDisconnected: isDisconnected)
                        .tag(AppFeature.Tab.media)
                        .tabItem {
                            Label(
                                AppFeature.Tab.media.title,
                                systemImage: AppFeature.Tab.media.icon
                            )
                        }

                    ProductivityView(store: store.scope(state: \.productivity, action: \.productivity))
                        .connectionBlur(isDisconnected: isDisconnected)
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
                        Task { @MainActor in
                            HapticManager.shared.buttonTap()
                        }
                        store.send(.showConnectionSheet)
                    } label: {
                        connectionIcon
                    }
                    .accessibilityLabel(connectionAccessibilityLabel)
                    .accessibilityHint("탭하여 연결 설정을 엽니다")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { @MainActor in
                            HapticManager.shared.buttonTap()
                        }
                        store.send(.showSettings)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(SnapColors.textSecondary)
                    }
                    .accessibilityLabel("설정")
                }
            }
            .toolbarBackground(SnapColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
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
            store.send(.settings(.onAppear))
        }
        .tint(store.settings.accentColor.color)
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

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    let status: ConnectionStatus
    let signalStrength: SignalStrength

    var body: some View {
        HStack(spacing: SnapSpacing.sm) {
            statusIcon
            statusText
            Spacer()
            if status.isConnected {
                signalIndicator
            }
        }
        .padding(.horizontal, SnapSpacing.lg)
        .padding(.vertical, SnapSpacing.sm)
        .background(backgroundColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = statusMessage
        if status.isConnected {
            label += ", 신호 강도: \(signalStrengthLabel)"
        }
        return label
    }

    private var signalStrengthLabel: String {
        switch signalStrength {
        case .strong: return "강함"
        case .moderate: return "보통"
        case .weak: return "약함"
        case .unknown: return "알 수 없음"
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .disconnected:
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SnapColors.statusDisconnected)
        case .discovering, .connecting:
            ProgressView()
                .scaleEffect(0.7)
                .tint(SnapColors.statusConnecting)
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SnapColors.statusConnected)
        case .reconnecting:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SnapColors.statusConnecting)
        }
    }

    private var statusText: some View {
        Text(statusMessage)
            .font(SnapTypography.labelMedium)
            .foregroundStyle(SnapColors.textSecondary)
    }

    private var statusMessage: String {
        switch status {
        case .disconnected:
            "연결 안됨"
        case .discovering:
            "검색 중..."
        case .connecting(let device):
            "\(device.name)에 연결 중..."
        case .connected(let device):
            "\(device.name)에 연결됨"
        case .reconnecting(_, let attempt):
            "재연결 중... (\(attempt)/3)"
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
            SnapColors.statusConnected
        case .moderate:
            index < 2 ? SnapColors.statusConnecting : SnapColors.textDisabled
        case .weak:
            index < 1 ? SnapColors.statusDisconnected : SnapColors.textDisabled
        case .unknown:
            SnapColors.textDisabled
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .disconnected:
            SnapColors.statusDisconnected.opacity(0.1)
        case .discovering, .connecting:
            SnapColors.statusConnecting.opacity(0.1)
        case .connected:
            SnapColors.statusConnected.opacity(0.1)
        case .reconnecting:
            SnapColors.statusConnecting.opacity(0.1)
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
                .foregroundStyle(SnapColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SnapColors.systemBackground)
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
                .foregroundStyle(SnapColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SnapColors.systemBackground)
    }
}

// MARK: - Sheet Views

struct ConnectionSheetView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: SnapSpacing.xxl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(SnapColors.cyberBlue.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "wifi")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(SnapColors.cyberBlue)
                }
                .glowAnimation(color: SnapColors.cyberBlue, isActive: true)

                VStack(spacing: SnapSpacing.sm) {
                    Text("Mac에 연결")
                        .font(SnapTypography.headlineLarge)
                        .foregroundStyle(SnapColors.textPrimary)

                    Text("Mac에서 Snap Receiver가 실행 중인지 확인하세요")
                        .font(SnapTypography.bodyMedium)
                        .foregroundStyle(SnapColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: SnapSpacing.md) {
                    ProgressView()
                        .tint(SnapColors.cyberBlue)

                    Text("기기 검색 중...")
                        .font(SnapTypography.labelMedium)
                        .foregroundStyle(SnapColors.textTertiary)
                }

                Spacer()
            }
            .padding(SnapSpacing.xl)
            .background(SnapColors.background)
            .navigationTitle("연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SnapColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        Task { @MainActor in
                            HapticManager.shared.buttonTap()
                        }
                        onDismiss()
                    }
                    .foregroundStyle(SnapColors.cyberBlue)
                }
            }
        }
        .preferredColorScheme(.dark)
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
            VStack(spacing: SnapSpacing.xxl) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(SnapColors.neonLime.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.shield")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(SnapColors.neonLime)
                }
                .glowAnimation(color: SnapColors.neonLime, isActive: true)

                // Title
                VStack(spacing: SnapSpacing.sm) {
                    Text("PIN 코드 입력")
                        .font(SnapTypography.headlineLarge)
                        .foregroundStyle(SnapColors.textPrimary)

                    Text("\(serverName)에 표시된\n4자리 PIN을 입력하세요")
                        .font(SnapTypography.bodyMedium)
                        .foregroundStyle(SnapColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // PIN Input
                VStack(spacing: SnapSpacing.lg) {
                    // Hidden text field
                    TextField("", text: $pinCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isTextFieldFocused)
                        .opacity(0)
                        .frame(width: 1, height: 1)
                        .onChange(of: pinCode) { _, newValue in
                            // 4자리로 제한
                            if newValue.count > 4 {
                                pinCode = String(newValue.prefix(4))
                            }
                            // 숫자만 허용
                            pinCode = newValue.filter { $0.isNumber }

                            // 입력 시 햅틱
                            if !newValue.isEmpty {
                                Task { @MainActor in
                                    HapticManager.shared.lightImpact()
                                }
                            }
                        }

                    // PIN Display
                    HStack(spacing: SnapSpacing.lg) {
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
                    Task { @MainActor in
                        HapticManager.shared.success()
                    }
                    onSubmit()
                } label: {
                    Text("연결")
                        .font(SnapTypography.labelLarge)
                        .foregroundStyle(SnapColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(pinCode.count == 4 ? SnapColors.neonLime : SnapColors.textDisabled)
                        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
                }
                .disabled(pinCode.count != 4)
                .padding(.horizontal, SnapSpacing.lg)
                .pressEffect()

                Spacer()
            }
            .padding(SnapSpacing.xl)
            .background(SnapColors.background)
            .navigationTitle("페어링")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SnapColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        Task { @MainActor in
                            HapticManager.shared.buttonTap()
                        }
                        onCancel()
                    }
                    .foregroundStyle(SnapColors.neonRed)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private func pinDigitView(at index: Int) -> some View {
        let digit = pinCode.count > index ? String(pinCode[pinCode.index(pinCode.startIndex, offsetBy: index)]) : ""
        let isFilled = !digit.isEmpty

        ZStack {
            RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                .stroke(isFilled ? SnapColors.neonLime : SnapColors.border, lineWidth: isFilled ? 2 : 1)
                .frame(width: 56, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                        .fill(SnapColors.backgroundElevated)
                )

            if isFilled {
                Text(digit)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(SnapColors.neonLime)
            } else {
                Circle()
                    .fill(SnapColors.textDisabled)
                    .frame(width: 10, height: 10)
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isFilled)
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
