import ComposableArchitecture
import SwiftUI

public struct TrackpadView: View {
    @Bindable var store: StoreOf<TrackpadFeature>

    public init(store: StoreOf<TrackpadFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mode Toggle
            modeToggle
                .padding()

            // Main Content
            if store.mode == .trackpad {
                trackpadContent
            } else {
                laserContent
            }

            // Quick Actions
            quickActions
                .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Mode Toggle

    @ViewBuilder
    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TrackpadFeature.InputMode.allCases, id: \.self) { mode in
                Button {
                    store.send(.modeChanged(mode))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .trackpad ? "hand.point.up.left" : "scope")
                            .font(.system(size: 14, weight: .medium))
                        Text(mode.title)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(store.mode == mode ? Color(.systemGray5) : Color.clear)
                    .foregroundStyle(store.mode == mode ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Trackpad Content

    @ViewBuilder
    private var trackpadContent: some View {
        VStack(spacing: 16) {
            // Touch Area
            TrackpadTouchArea(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Click Buttons
            HStack(spacing: 16) {
                // Left Click
                ClickButton(label: "L", isPrimary: true) {
                    store.send(.leftClickPressed)
                } onRelease: {
                    store.send(.leftClickReleased)
                }

                // Right Click
                ClickButton(label: "R", isPrimary: false) {
                    store.send(.rightClickPressed)
                } onRelease: {
                    store.send(.rightClickReleased)
                }
            }
            .frame(height: 60)
            .padding(.horizontal)
        }
    }

    // MARK: - Laser Content (Placeholder)

    @ViewBuilder
    private var laserContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "scope")
                .font(.system(size: 80))
                .foregroundStyle(.red.opacity(0.5))

            Text("Laser Mode")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming Soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActions: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                icon: "magnifyingglass",
                label: "Spotlight"
            ) {
                store.send(.spotlightPressed)
            }

            QuickActionButton(
                icon: "rectangle.3.group",
                label: "Mission Control"
            ) {
                store.send(.missionControlPressed)
            }
        }
    }
}

// MARK: - Trackpad Touch Area

struct TrackpadTouchArea: View {
    let store: StoreOf<TrackpadFeature>

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color(.systemGray4), lineWidth: 1)
                    )

                // Watermark
                Text("TRACKPAD")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.quaternary)
                    .tracking(8)

                // Touch indicator
                if store.isTouching {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .position(store.lastTouchPosition)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !store.isTouching {
                            store.send(.touchBegan(value.location))
                        } else {
                            store.send(.touchMoved(value.location))
                        }
                    }
                    .onEnded { _ in
                        store.send(.touchEnded)
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        store.send(.tapped)
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        store.send(.doubleTapped)
                    }
            )
            .highPriorityGesture(
                MagnifyGesture()
                    .onChanged { value in
                        // Two-finger scroll approximation
                        let delta = Float(value.magnification - 1) * 10
                        store.send(.scrolled(deltaX: 0, deltaY: CGFloat(delta)))
                    }
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Click Button

struct ClickButton: View {
    let label: String
    let isPrimary: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(isPrimary ? .blue : .secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPressed ? Color(.systemGray4) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(
                minimumDuration: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                    if pressing {
                        onPress()
                    } else {
                        onRelease()
                    }
                },
                perform: {}
            )
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TrackpadView(
        store: Store(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        }
    )
}
