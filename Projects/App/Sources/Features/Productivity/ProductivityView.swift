import ComposableArchitecture
import Shared
import SwiftUI

public struct ProductivityView: View {
    @Bindable var store: StoreOf<ProductivityFeature>

    public init(store: StoreOf<ProductivityFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Macro Pad Section
                macroSection

                // Siri Section
                siriSection

                // Window Snap Section
                windowSnapSection

                // App Switcher Section
                appSwitcherSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Macro Section

    @ViewBuilder
    private var macroSection: some View {
        MacroPadSection(
            store: store.scope(state: \.macro, action: \.macro)
        )
    }

    // MARK: - Siri Section

    @ViewBuilder
    private var siriSection: some View {
        VStack(spacing: 16) {
            Text("Siri")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                // Siri Button
                SiriButton(isActive: store.isSiriActive) {
                    store.send(.siriTapped)
                }

                // Dictation Button
                Button {
                    store.send(.dictationTapped(""))
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 24))
                        Text("받아쓰기")
                            .font(.caption)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Window Snap Section

    @ViewBuilder
    private var windowSnapSection: some View {
        VStack(spacing: 16) {
            Text("윈도우 스냅")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                WindowSnapButton(icon: "rectangle.lefthalf.filled", label: "왼쪽") {
                    store.send(.windowSnapTapped(.leftHalf))
                }
                WindowSnapButton(icon: "rectangle.righthalf.filled", label: "오른쪽") {
                    store.send(.windowSnapTapped(.rightHalf))
                }
                WindowSnapButton(icon: "rectangle.tophalf.filled", label: "상단") {
                    store.send(.windowSnapTapped(.topHalf))
                }
                WindowSnapButton(icon: "rectangle.bottomhalf.filled", label: "하단") {
                    store.send(.windowSnapTapped(.bottomHalf))
                }
                WindowSnapButton(icon: "arrow.up.left.and.arrow.down.right", label: "전체화면") {
                    store.send(.windowSnapTapped(.fullScreen))
                }
                WindowSnapButton(icon: "rectangle.center.inset.filled", label: "가운데") {
                    store.send(.windowSnapTapped(.center))
                }
                WindowSnapButton(icon: "rectangle.topthird.inset.filled", label: "좌상단") {
                    store.send(.windowSnapTapped(.topLeft))
                }
                WindowSnapButton(icon: "rectangle.bottomthird.inset.filled", label: "우하단") {
                    store.send(.windowSnapTapped(.bottomRight))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - App Switcher Section

    @ViewBuilder
    private var appSwitcherSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("앱 스위처")
                    .font(.headline)

                Spacer()

                Button {
                    store.send(.requestAppListTapped)
                } label: {
                    if store.isLoadingApps {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(store.isLoadingApps)
            }

            if store.runningApps.isEmpty {
                // Empty state
                HStack {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("앱 목록 불러오기")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Mac에서 실행 중인 앱 목록")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("불러오기") {
                        store.send(.requestAppListTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(store.isLoadingApps)
                }
            } else {
                // App grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(store.runningApps, id: \.bundleID) { app in
                        AppButton(app: app, isActive: app.isActive) {
                            store.send(.appTapped(app))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - App Button

struct AppButton: View {
    let app: AppInfo
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // App icon
                if let uiImage = UIImage(data: app.iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.purple)
                        .frame(width: 48, height: 48)
                }

                // App name
                Text(app.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(isActive ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.purple.opacity(0.15) : Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(app.name) 앱\(isActive ? ", 활성화됨" : "")")
    }
}

// MARK: - Siri Button

struct SiriButton: View {
    let isActive: Bool
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow effect when active
                if isActive {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.4),
                                    Color.pink.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                }

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isActive
                                ? [Color.purple, Color.pink, Color.orange]
                                : [Color(.systemGray4), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: isActive ? Color.purple.opacity(0.5) : Color.clear,
                        radius: 10
                    )

                // Icon
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, isActive: isActive)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

// MARK: - Window Snap Button

struct WindowSnapButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProductivityView(
        store: Store(initialState: ProductivityFeature.State()) {
            ProductivityFeature()
        }
    )
}
