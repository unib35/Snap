import ComposableArchitecture
import SwiftUI

public struct ProductivityView: View {
    @Bindable var store: StoreOf<ProductivityFeature>

    public init(store: StoreOf<ProductivityFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Siri Section
                siriSection

                // Window Snap Section (Placeholder)
                windowSnapSection

                // App Switcher Section (Placeholder)
                appSwitcherSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
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
                WindowSnapButton(icon: "rectangle.lefthalf.filled", label: "왼쪽")
                WindowSnapButton(icon: "rectangle.righthalf.filled", label: "오른쪽")
                WindowSnapButton(icon: "rectangle.tophalf.filled", label: "상단")
                WindowSnapButton(icon: "rectangle.bottomhalf.filled", label: "하단")
                WindowSnapButton(icon: "arrow.up.left.and.arrow.down.right", label: "전체화면")
                WindowSnapButton(icon: "rectangle.center.inset.filled", label: "가운데")
                WindowSnapButton(icon: "rectangle.topthird.inset.filled", label: "좌상단")
                WindowSnapButton(icon: "rectangle.bottomthird.inset.filled", label: "우하단")
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
            Text("앱 스위처")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

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
                    // TODO: Request app list
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

    var body: some View {
        Button {
            // TODO: Send window snap command
        } label: {
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
