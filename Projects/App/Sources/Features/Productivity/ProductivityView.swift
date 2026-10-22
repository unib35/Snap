import ComposableArchitecture
import Shared
import SwiftUI

public struct ProductivityView: View {
    @Bindable var store: StoreOf<ProductivityFeature>

    public init(store: StoreOf<ProductivityFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("Mac 작업") {
                toolLink("창 정렬", subtitle: "현재 창을 화면의 원하는 위치로", icon: "rectangle.split.2x1") {
                    windowSnapSection
                }
                toolLink("앱 전환", subtitle: "실행 중인 앱으로 바로 이동", icon: "macwindow.on.rectangle") {
                    appSwitcherSection
                }
                toolLink("빠른 실행", subtitle: "자주 쓰는 앱과 웹사이트 열기", icon: "bolt") {
                    quickLaunchSection
                }
                toolLink("매크로", subtitle: "여러 작업을 한 번에 실행", icon: "square.stack") {
                    macroSection
                }
            }
            Section("발표와 콘텐츠") {
                toolLink("프레젠테이션", subtitle: "슬라이드 이동과 발표 타이머", icon: "rectangle.on.rectangle") {
                    presenterSection
                }
                toolLink("숏폼 리모컨", subtitle: "짧은 영상 넘기기와 재생 제어", icon: "play.rectangle") {
                    shortsRemoteSection
                }
            }
            Section("음성") {
                toolLink("음성 입력", subtitle: "말한 내용을 Mac에 입력", icon: "mic") {
                    voiceTypingSection
                }
                toolLink("Mac의 Siri", subtitle: "Mac에서 Siri 호출", icon: "waveform") {
                    siriSection
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SnapColors.background)
        // Presenter Full Screen
        .fullScreenCover(isPresented: presenterBinding) {
            PresenterFullScreenView(
                store: store.scope(state: \.presenter, action: \.presenter)
            )
        }
        // Shorts Remote Full Screen
        .fullScreenCover(isPresented: shortsRemoteBinding) {
            ShortsRemoteFullScreenView(
                store: store.scope(state: \.shortsRemote, action: \.shortsRemote)
            )
        }
    }

    private func toolLink<Destination: View>(
        _ title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            ScrollView {
                destination()
                    .frame(maxWidth: 680)
                    .padding(SnapSpacing.lg)
                    .frame(maxWidth: .infinity)
            }
            .background(SnapColors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.body.weight(.medium)).foregroundStyle(SnapColors.textPrimary)
                    Text(subtitle).font(.caption).foregroundStyle(SnapColors.textSecondary)
                }
                .padding(.vertical, 5)
            }
        }
        .listRowBackground(SnapColors.backgroundElevated)
    }

    // MARK: - Full Screen Bindings

    private var presenterBinding: Binding<Bool> {
        Binding(
            get: { store.presenter.isPresenting },
            set: { newValue in
                if !newValue {
                    store.send(.presenter(.endPresentation))
                }
            }
        )
    }

    private var shortsRemoteBinding: Binding<Bool> {
        Binding(
            get: { store.shortsRemote.isActive },
            set: { newValue in
                if !newValue {
                    store.send(.shortsRemote(.stop))
                }
            }
        )
    }

    // MARK: - Quick Launch Section

    @ViewBuilder
    private var quickLaunchSection: some View {
        QuickLaunchSection(
            store: store.scope(state: \.quickLaunch, action: \.quickLaunch)
        )
    }

    // MARK: - Shorts Remote Section

    @ViewBuilder
    private var shortsRemoteSection: some View {
        ShortsRemoteSection(
            store: store.scope(state: \.shortsRemote, action: \.shortsRemote)
        )
    }

    // MARK: - Presenter Section

    @ViewBuilder
    private var presenterSection: some View {
        PresenterSection(
            store: store.scope(state: \.presenter, action: \.presenter)
        )
    }

    // MARK: - Macro Section

    @ViewBuilder
    private var macroSection: some View {
        MacroPadSection(
            store: store.scope(state: \.macro, action: \.macro)
        )
    }

    // MARK: - Voice Typing Section

    @ViewBuilder
    private var voiceTypingSection: some View {
        VoiceTypingView(
            store: store.scope(state: \.voiceTyping, action: \.voiceTyping)
        )
        .padding(SnapSpacing.lg)
        .cardStyle()
    }

    // MARK: - Siri Section

    private var siriSection: some View {
        VStack(alignment: .leading, spacing: SnapSpacing.lg) {
            Text("Mac에 설정된 Siri를 호출합니다. Mac의 마이크를 향해 말하세요.")
                .font(.subheadline)
                .foregroundStyle(SnapColors.textSecondary)
            Button { store.send(.siriTapped) } label: {
                Label("Siri 호출", systemImage: "waveform")
            }
            .buttonStyle(SnapActionButtonStyle())
        }
        .padding(SnapSpacing.lg)
        .cardStyle()
    }

    // MARK: - Window Snap Section

    @ViewBuilder
    private var windowSnapSection: some View {
        VStack(spacing: SnapSpacing.lg) {
            Text("윈도우 스냅")
                .font(SnapTypography.headlineMedium)
                .foregroundStyle(SnapColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: SnapSpacing.md) {
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
        .padding(SnapSpacing.lg)
        .cardStyle()
    }

    // MARK: - App Switcher Section

    @ViewBuilder
    private var appSwitcherSection: some View {
        VStack(spacing: SnapSpacing.lg) {
            HStack {
                Text("앱 스위처")
                    .font(SnapTypography.headlineMedium)
                    .foregroundStyle(SnapColors.textPrimary)

                Spacer()

                if !store.runningApps.isEmpty {
                    Button {
                        Task { @MainActor in
                            HapticManager.shared.buttonTap()
                        }
                        store.send(.toggleAppSwitcherEditMode)
                    } label: {
                        Text(store.isAppSwitcherEditing ? "완료" : "편집")
                            .font(SnapTypography.labelSmall)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal, SnapSpacing.md)
                    .padding(.vertical, SnapSpacing.xs)
                    .background(SnapColors.backgroundTertiary)
                    .clipShape(Capsule())
                }

                Button {
                    Task { @MainActor in
                        HapticManager.shared.buttonTap()
                    }
                    store.send(.requestAppListTapped)
                } label: {
                    if store.isLoadingApps {
                        ProgressView()
                            .tint(.accentColor)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(SnapSpacing.sm)
                .background(SnapColors.backgroundTertiary)
                .clipShape(Circle())
                .disabled(store.isLoadingApps)
            }

            if store.runningApps.isEmpty {
                // Empty state
                HStack(spacing: SnapSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(alignment: .leading, spacing: SnapSpacing.xxs) {
                        Text("앱 목록 불러오기")
                            .font(SnapTypography.labelLarge)
                            .foregroundStyle(SnapColors.textPrimary)
                        Text("Mac에서 실행 중인 앱 목록")
                            .font(SnapTypography.labelSmall)
                            .foregroundStyle(SnapColors.textTertiary)
                    }

                    Spacer()

                    SnapSecondaryButton("불러오기", accentColor: .accentColor) {
                        store.send(.requestAppListTapped)
                    }
                    .frame(width: 100)
                    .disabled(store.isLoadingApps)
                }
            } else {
                // App grid with reordering
                let sortedApps = store.sortedApps
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: SnapSpacing.lg) {
                    ForEach(Array(sortedApps.enumerated()), id: \.element.bundleID) { index, app in
                        AppButton(
                            app: app,
                            isActive: app.isActive,
                            isEditing: store.isAppSwitcherEditing
                        ) {
                            if !store.isAppSwitcherEditing {
                                store.send(.appTapped(app))
                            }
                        }
                        .draggable(app.bundleID) {
                            AppDragPreview(app: app)
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let droppedBundleID = items.first,
                                  let fromIndex = sortedApps.firstIndex(where: { $0.bundleID == droppedBundleID }) else {
                                return false
                            }
                            HapticManager.shared.selection()
                            store.send(.appMoved(from: IndexSet(integer: fromIndex), to: index))
                            return true
                        }
                    }
                }
            }
        }
        .padding(SnapSpacing.lg)
        .cardStyle()
        .onAppear {
            store.send(.loadAppOrder)
        }
    }
}

// MARK: - App Button

struct AppButton: View {
    let app: AppInfo
    let isActive: Bool
    var isEditing: Bool = false
    let action: () -> Void

    @State private var isWiggling = false

    var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.buttonTap()
            }
            action()
        } label: {
            VStack(spacing: SnapSpacing.sm) {
                // App icon
                if let uiImage = UIImage(data: app.iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 48, height: 48)
                }

                // App name
                Text(app.name)
                    .font(SnapTypography.caption)
                    .lineLimit(1)
                    .foregroundStyle(isActive ? SnapColors.textPrimary : SnapColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SnapSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                    .fill(isActive ? Color.accentColor.opacity(0.15) : SnapColors.backgroundTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                    .strokeBorder(isEditing ? Color.accentColor : (isActive ? Color.accentColor.opacity(0.5) : Color.clear), lineWidth: isEditing ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .pressEffect()
        .rotationEffect(.degrees(isWiggling ? 1.5 : -1.5))
        .animation(
            isEditing ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true) : .default,
            value: isWiggling
        )
        .onChange(of: isEditing) { _, newValue in
            isWiggling = newValue
        }
        .accessibilityLabel("\(app.name) 앱\(isActive ? ", 활성화됨" : "")\(isEditing ? ", 편집 모드" : "")")
    }
}

// MARK: - App Drag Preview

struct AppDragPreview: View {
    let app: AppInfo

    var body: some View {
        VStack(spacing: SnapSpacing.xs) {
            if let uiImage = UIImage(data: app.iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 56, height: 56)
            }

            Text(app.name)
                .font(SnapTypography.caption)
                .foregroundStyle(SnapColors.textPrimary)
        }
        .padding(SnapSpacing.sm)
        .background(SnapColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Window Snap Button

struct WindowSnapButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.buttonTap()
            }
            action()
        } label: {
            VStack(spacing: SnapSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                Text(label)
                    .font(SnapTypography.caption)
                    .foregroundStyle(SnapColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(SnapColors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
        }
        .buttonStyle(.plain)
        .pressEffect()
        .accessibilityLabel("윈도우를 \(label)으로 스냅")
    }
}

#Preview {
    ProductivityView(
        store: Store(initialState: ProductivityFeature.State()) {
            ProductivityFeature()
        }
    )
}
