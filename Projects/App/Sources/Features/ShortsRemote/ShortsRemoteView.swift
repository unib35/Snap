import ComposableArchitecture
import SwiftUI
import UIKit

public struct ShortsRemoteView: View {
    @Bindable var store: StoreOf<ShortsRemoteFeature>

    public init(store: StoreOf<ShortsRemoteFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Platform Picker
            platformPicker

            // Swipe Navigation Area
            swipeArea

            // Control Buttons
            controlButtons
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Platform Picker

    private var platformPicker: some View {
        HStack(spacing: 12) {
            ForEach(ShortsRemoteFeature.Platform.allCases, id: \.self) { platform in
                PlatformButton(
                    platform: platform,
                    isSelected: store.selectedPlatform == platform
                ) {
                    store.send(.platformSelected(platform))
                }
            }
        }
    }

    // MARK: - Swipe Area

    private var swipeArea: some View {
        SwipeNavigationArea(
            onSwipeUp: { store.send(.nextVideo) },
            onSwipeDown: { store.send(.previousVideo) }
        )
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Seek Backward
            ShortsControlButton(
                icon: "gobackward.5",
                label: "-5s"
            ) {
                store.send(.seekBackward)
            }

            // Play/Pause
            ShortsControlButton(
                icon: store.isPaused ? "play.fill" : "pause.fill",
                label: store.isPaused ? "재생" : "일시정지",
                isLarge: true
            ) {
                store.send(.togglePlayPause)
            }

            // Seek Forward
            ShortsControlButton(
                icon: "goforward.5",
                label: "+5s"
            ) {
                store.send(.seekForward)
            }

            // Mute
            ShortsControlButton(
                icon: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: store.isMuted ? "음소거 해제" : "음소거"
            ) {
                store.send(.toggleMute)
            }
        }
    }
}

// MARK: - Platform Button

struct PlatformButton: View {
    let platform: ShortsRemoteFeature.Platform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: platform.icon)
                    .font(.system(size: 24))

                Text(platform.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? platformColor.opacity(0.15) : Color(.tertiarySystemBackground))
            )
            .foregroundStyle(isSelected ? platformColor : .secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? platformColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var platformColor: Color {
        switch platform {
        case .youtube: return .red
        case .instagram: return .pink
        case .tiktok: return .primary
        }
    }
}

// MARK: - Swipe Navigation Area

struct SwipeNavigationArea: View {
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showUpIndicator = false
    @State private var showDownIndicator = false

    private let threshold: CGFloat = 50

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color(.separator), lineWidth: 1)
                    )

                // Content
                VStack(spacing: 20) {
                    // Up indicator
                    VStack(spacing: 8) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(showDownIndicator ? .primary : .tertiary)

                        Text("이전 영상")
                            .font(.caption)
                            .foregroundStyle(showDownIndicator ? .primary : .tertiary)
                    }
                    .opacity(showDownIndicator ? 1 : 0.5)

                    Spacer()

                    // Center instructions
                    VStack(spacing: 12) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("위아래로 스와이프")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .offset(y: offset * 0.3)

                    Spacer()

                    // Down indicator
                    VStack(spacing: 8) {
                        Text("다음 영상")
                            .font(.caption)
                            .foregroundStyle(showUpIndicator ? .primary : .tertiary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(showUpIndicator ? .primary : .tertiary)
                    }
                    .opacity(showUpIndicator ? 1 : 0.5)
                }
                .padding(.vertical, 30)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.height
                        withAnimation(.easeOut(duration: 0.1)) {
                            showUpIndicator = offset < -threshold
                            showDownIndicator = offset > threshold
                        }
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.height - value.translation.height

                        if offset < -threshold || velocity < -100 {
                            // Swipe up -> next video
                            triggerHaptic()
                            onSwipeUp()
                        } else if offset > threshold || velocity > 100 {
                            // Swipe down -> previous video
                            triggerHaptic()
                            onSwipeDown()
                        }

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = 0
                            showUpIndicator = false
                            showDownIndicator = false
                        }
                    }
            )
        }
        .frame(height: 280)
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Shorts Control Button

struct ShortsControlButton: View {
    let icon: String
    let label: String
    var isLarge: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 28 : 22))

                Text(label)
                    .font(.caption2)
            }
            .frame(width: isLarge ? 80 : 60, height: isLarge ? 80 : 60)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemBackground))
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Shorts Remote Section (for embedding in ProductivityView)

public struct ShortsRemoteSection: View {
    @Bindable var store: StoreOf<ShortsRemoteFeature>

    public init(store: StoreOf<ShortsRemoteFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(Color.accentColor)
                Text("숏폼 리모컨")
                    .font(.headline)
                Spacer()
            }

            // Platform Picker
            HStack(spacing: 8) {
                ForEach(ShortsRemoteFeature.Platform.allCases, id: \.self) { platform in
                    PlatformChip(
                        platform: platform,
                        isSelected: store.selectedPlatform == platform
                    ) {
                        store.send(.platformSelected(platform))
                    }
                }
            }

            // Compact Swipe Area
            CompactSwipeArea(
                onSwipeUp: { store.send(.nextVideo) },
                onSwipeDown: { store.send(.previousVideo) }
            )

            // Compact Controls
            HStack(spacing: 12) {
                CompactControlButton(icon: "gobackward.5") {
                    store.send(.seekBackward)
                }

                CompactControlButton(
                    icon: store.isPaused ? "play.fill" : "pause.fill",
                    isHighlighted: true
                ) {
                    store.send(.togglePlayPause)
                }

                CompactControlButton(icon: "goforward.5") {
                    store.send(.seekForward)
                }

                Spacer()

                CompactControlButton(
                    icon: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
                ) {
                    store.send(.toggleMute)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Platform Chip

struct PlatformChip: View {
    let platform: ShortsRemoteFeature.Platform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: platform.icon)
                    .font(.system(size: 14))

                Text(platform.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? platformColor.opacity(0.15) : Color(.tertiarySystemBackground))
            )
            .foregroundStyle(isSelected ? platformColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var platformColor: Color {
        switch platform {
        case .youtube: return .red
        case .instagram: return .pink
        case .tiktok: return .primary
        }
    }
}

// MARK: - Compact Swipe Area

struct CompactSwipeArea: View {
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void

    @State private var offset: CGFloat = 0

    private let threshold: CGFloat = 30

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))

            HStack {
                // Up/Previous
                VStack(spacing: 4) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 20, weight: .semibold))
                    Text("이전")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(offset > threshold ? .primary : .tertiary)

                Divider()
                    .frame(height: 40)

                // Center
                VStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 24))
                    Text("스와이프")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)

                Divider()
                    .frame(height: 40)

                // Down/Next
                VStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                    Text("다음")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(offset < -threshold ? .primary : .tertiary)
            }
            .padding(.vertical, 12)
        }
        .frame(height: 80)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.height
                }
                .onEnded { _ in
                    if offset < -threshold {
                        triggerHaptic()
                        onSwipeUp()
                    } else if offset > threshold {
                        triggerHaptic()
                        onSwipeDown()
                    }
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
        )
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Compact Control Button

struct CompactControlButton: View {
    let icon: String
    var isHighlighted: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHighlighted ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemBackground))
                )
                .foregroundStyle(isHighlighted ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    ShortsRemoteView(
        store: Store(initialState: ShortsRemoteFeature.State()) {
            ShortsRemoteFeature()
        }
    )
}

#Preview("Section") {
    ShortsRemoteSection(
        store: Store(initialState: ShortsRemoteFeature.State()) {
            ShortsRemoteFeature()
        }
    )
    .padding()
}
