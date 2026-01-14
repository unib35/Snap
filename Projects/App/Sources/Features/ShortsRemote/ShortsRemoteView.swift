import ComposableArchitecture
import SwiftUI

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
        .background(SnapColors.systemBackground)
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
                    .fill(isSelected ? platformColor.opacity(0.15) : SnapColors.tertiarySystemBackground)
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
                    .fill(SnapColors.secondarySystemBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(SnapColors.separator, lineWidth: 1)
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
                            .foregroundStyle(SnapColors.textSecondary)

                        Text("위아래로 스와이프")
                            .font(.subheadline)
                            .foregroundStyle(SnapColors.textSecondary)
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
                            Task { @MainActor in
                                HapticManager.shared.mediumImpact()
                            }
                            onSwipeUp()
                        } else if offset > threshold || velocity > 100 {
                            // Swipe down -> previous video
                            Task { @MainActor in
                                HapticManager.shared.mediumImpact()
                            }
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
}

// MARK: - Shorts Control Button

struct ShortsControlButton: View {
    let icon: String
    let label: String
    var isLarge: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.lightImpact()
            }
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
                    .fill(SnapColors.tertiarySystemBackground)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
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

                // Full Screen Button
                Button {
                    HapticManager.shared.mediumImpact()
                    store.send(.start)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("전체화면")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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
        .background(SnapColors.secondarySystemBackground.opacity(0.5))
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
                    .fill(isSelected ? platformColor.opacity(0.15) : SnapColors.tertiarySystemBackground)
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
                .fill(SnapColors.tertiarySystemBackground)

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
                .foregroundStyle(SnapColors.textSecondary)

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
                        Task { @MainActor in
                            HapticManager.shared.mediumImpact()
                        }
                        onSwipeUp()
                    } else if offset > threshold {
                        Task { @MainActor in
                            HapticManager.shared.mediumImpact()
                        }
                        onSwipeDown()
                    }
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
        )
    }
}

// MARK: - Compact Control Button

struct CompactControlButton: View {
    let icon: String
    var isHighlighted: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.lightImpact()
            }
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHighlighted ? Color.accentColor.opacity(0.15) : SnapColors.tertiarySystemBackground)
                )
                .foregroundStyle(isHighlighted ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
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

// MARK: - Full Screen View

public struct ShortsRemoteFullScreenView: View {
    @Bindable var store: StoreOf<ShortsRemoteFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<ShortsRemoteFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Full Screen Swipe Area
                fullScreenSwipeArea(geometry: geometry)

                // Overlay Controls
                VStack {
                    // Top Bar
                    topBar

                    Spacer()

                    // Bottom Controls
                    bottomControls
                }
                .padding()

                // Side Actions (YouTube Style)
                sideActions
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .statusBarHidden()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Platform Indicator
            HStack(spacing: 8) {
                Image(systemName: store.selectedPlatform.icon)
                Text(store.selectedPlatform.rawValue)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

            // Close Button
            Button {
                store.send(.stop)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Full Screen Swipe Area

    private func fullScreenSwipeArea(geometry: GeometryProxy) -> some View {
        ZStack {
            // Swipe detection area
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            let verticalMovement = value.translation.height
                            let horizontalMovement = value.translation.width

                            // Prioritize vertical swipes
                            if abs(verticalMovement) > abs(horizontalMovement) {
                                if verticalMovement < -50 {
                                    // Swipe up -> next video
                                    HapticManager.shared.mediumImpact()
                                    store.send(.nextVideo)
                                } else if verticalMovement > 50 {
                                    // Swipe down -> previous video
                                    HapticManager.shared.mediumImpact()
                                    store.send(.previousVideo)
                                }
                            } else {
                                // Horizontal swipes for seek
                                if horizontalMovement > 50 {
                                    HapticManager.shared.lightImpact()
                                    store.send(.seekForward)
                                } else if horizontalMovement < -50 {
                                    HapticManager.shared.lightImpact()
                                    store.send(.seekBackward)
                                }
                            }
                        }
                )
                .onTapGesture {
                    // Tap to play/pause
                    HapticManager.shared.lightImpact()
                    store.send(.togglePlayPause)
                }

            // Visual Guide
            VStack(spacing: 24) {
                // Up indicator
                VStack(spacing: 8) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 32, weight: .bold))
                    Text("이전 영상")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.3))

                Spacer()

                // Center indicator
                VStack(spacing: 16) {
                    Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("탭하여 \(store.isPaused ? "재생" : "일시정지")")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                // Down indicator
                VStack(spacing: 8) {
                    Text("다음 영상")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 32, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.vertical, 80)
        }
    }

    // MARK: - Side Actions (YouTube Style)

    private var sideActions: some View {
        VStack(spacing: 24) {
            Spacer()

            // Like Button
            SideActionButton(
                icon: store.isLiked ? "heart.fill" : "heart",
                label: "좋아요",
                isActive: store.isLiked,
                activeColor: .red
            ) {
                store.send(.toggleLike)
            }

            // Mute Button
            SideActionButton(
                icon: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: store.isMuted ? "음소거" : "소리",
                isActive: store.isMuted,
                activeColor: .white
            ) {
                store.send(.toggleMute)
            }

            Spacer()
                .frame(height: 100)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 32) {
            // Seek Backward
            FullScreenControlButton(icon: "gobackward.10") {
                store.send(.seekBackward)
            }

            // Play/Pause (Large)
            FullScreenControlButton(
                icon: store.isPaused ? "play.fill" : "pause.fill",
                isLarge: true
            ) {
                store.send(.togglePlayPause)
            }

            // Seek Forward
            FullScreenControlButton(icon: "goforward.10") {
                store.send(.seekForward)
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Side Action Button

private struct SideActionButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    var activeColor: Color = .white
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.mediumImpact()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isActive ? activeColor : .white)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full Screen Control Button

private struct FullScreenControlButton: View {
    let icon: String
    var isLarge: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 36 : 24))
                .foregroundStyle(.white)
                .frame(width: isLarge ? 72 : 56, height: isLarge ? 72 : 56)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Section") {
    ShortsRemoteSection(
        store: Store(initialState: ShortsRemoteFeature.State()) {
            ShortsRemoteFeature()
        }
    )
    .padding()
}

#Preview("Full Screen") {
    var state = ShortsRemoteFeature.State()
    state.isActive = true
    return ShortsRemoteFullScreenView(
        store: Store(initialState: state) {
            ShortsRemoteFeature()
        }
    )
}
