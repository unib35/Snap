import ComposableArchitecture
import SwiftUI

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    let onComplete: () -> Void

    public init(store: StoreOf<OnboardingFeature>, onComplete: @escaping () -> Void) {
        self.store = store
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            SnapColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with skip button
                headerView

                // Page content
                TabView(selection: Binding(
                    get: { store.currentPage },
                    set: { store.send(.goToPage($0)) }
                )) {
                    ForEach(OnboardingPage.allCases, id: \.self) { page in
                        OnboardingPageView(page: page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: store.currentPage)

                // Bottom controls
                bottomControls
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: store.currentPage) { _, newValue in
            if newValue == .completion {
                // 완료 페이지에서 자동으로 완료 처리
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Spacer()

            if !store.currentPage.isLast {
                Button {
                    Task { @MainActor in
                        HapticManager.shared.buttonTap()
                    }
                    store.send(.skipOnboarding)
                    onComplete()
                } label: {
                    Text("건너뛰기")
                        .font(SnapTypography.labelLarge)
                        .foregroundStyle(SnapColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, SnapSpacing.xl)
        .padding(.top, SnapSpacing.lg)
        .frame(height: 44)
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        VStack(spacing: SnapSpacing.xl) {
            // Page indicators
            HStack(spacing: SnapSpacing.sm) {
                ForEach(OnboardingPage.allCases, id: \.self) { page in
                    Circle()
                        .fill(page == store.currentPage ? SnapColors.neonLime : SnapColors.textDisabled)
                        .frame(width: 8, height: 8)
                        .scaleEffect(page == store.currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: store.currentPage)
                }
            }
            .padding(.bottom, SnapSpacing.md)

            // Navigation buttons
            HStack(spacing: SnapSpacing.lg) {
                if store.canGoBack {
                    Button {
                        Task { @MainActor in
                            HapticManager.shared.buttonTap()
                        }
                        store.send(.previousPage)
                    } label: {
                        HStack(spacing: SnapSpacing.sm) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("이전")
                                .font(SnapTypography.labelLarge)
                        }
                        .foregroundStyle(SnapColors.textSecondary)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(SnapColors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                                .stroke(SnapColors.border, lineWidth: 1)
                        )
                    }
                    .pressEffect()
                }

                Button {
                    Task { @MainActor in
                        HapticManager.shared.buttonTap()
                    }
                    if store.currentPage.isLast {
                        store.send(.completeOnboarding)
                        onComplete()
                    } else {
                        store.send(.nextPage)
                    }
                } label: {
                    HStack(spacing: SnapSpacing.sm) {
                        Text(store.currentPage.isLast ? "시작하기" : "다음")
                            .font(SnapTypography.labelLarge)
                        if !store.currentPage.isLast {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundStyle(SnapColors.background)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(SnapColors.neonLime)
                    .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
                }
                .pressEffect()
            }
            .padding(.horizontal, SnapSpacing.xl)
            .padding(.bottom, SnapSpacing.xxl)
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: SnapSpacing.xxl) {
            Spacer()

            // Icon
            iconView
                .glowAnimation(color: iconColor, isActive: true)

            // Title and subtitle
            VStack(spacing: SnapSpacing.md) {
                Text(page.title)
                    .font(SnapTypography.displaySmall)
                    .foregroundStyle(SnapColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(SnapTypography.bodyMedium)
                    .foregroundStyle(SnapColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SnapSpacing.xxl)

            // Page-specific content
            pageContent
                .padding(.horizontal, SnapSpacing.xl)

            Spacer()
            Spacer()
        }
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 120, height: 120)

            Image(systemName: page.icon)
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }

    private var iconColor: Color {
        switch page {
        case .welcome:
            return SnapColors.neonLime
        case .features:
            return SnapColors.cyberBlue
        case .macReceiver:
            return SnapColors.neonPink
        case .connection:
            return SnapColors.cyberBlue
        case .permissions:
            return SnapColors.neonOrange
        case .completion:
            return SnapColors.neonLime
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .welcome:
            welcomeContent
        case .features:
            featuresContent
        case .macReceiver:
            macReceiverContent
        case .connection:
            connectionContent
        case .permissions:
            permissionsContent
        case .completion:
            completionContent
        }
    }

    // MARK: - Page Contents

    @ViewBuilder
    private var welcomeContent: some View {
        VStack(spacing: SnapSpacing.lg) {
            featureRow(icon: "hand.tap", title: "트랙패드", description: "정밀한 커서 제어")
            featureRow(icon: "keyboard", title: "키보드", description: "텍스트 입력 및 단축키")
            featureRow(icon: "music.note", title: "미디어", description: "음악 및 볼륨 컨트롤")
        }
        .padding(.top, SnapSpacing.lg)
    }

    @ViewBuilder
    private var featuresContent: some View {
        VStack(spacing: SnapSpacing.md) {
            featureCard(
                icon: "hand.tap.fill",
                color: SnapColors.neonLime,
                title: "트랙패드",
                description: "멀티터치 제스처로 Mac 커서를 자유롭게 제어"
            )

            featureCard(
                icon: "keyboard.fill",
                color: SnapColors.cyberBlue,
                title: "키보드",
                description: "텍스트 입력과 시스템 단축키 사용"
            )

            featureCard(
                icon: "play.circle.fill",
                color: SnapColors.neonPink,
                title: "미디어 컨트롤",
                description: "음악 재생, 볼륨 조절을 한 곳에서"
            )
        }
    }

    @ViewBuilder
    private var macReceiverContent: some View {
        VStack(spacing: SnapSpacing.xl) {
            VStack(alignment: .leading, spacing: SnapSpacing.md) {
                stepRow(number: 1, text: "Mac에서 Snap Receiver 앱 다운로드")
                stepRow(number: 2, text: "다운로드한 앱을 응용 프로그램 폴더로 이동")
                stepRow(number: 3, text: "Snap Receiver 앱 실행")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: SnapSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(SnapColors.cyberBlue)

                Text("Mac과 iPhone이 같은 Wi-Fi에 연결되어 있어야 합니다")
                    .font(SnapTypography.bodySmall)
                    .foregroundStyle(SnapColors.textSecondary)
            }
            .padding(SnapSpacing.md)
            .background(SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.sm))
        }
    }

    @ViewBuilder
    private var connectionContent: some View {
        VStack(spacing: SnapSpacing.xl) {
            connectionDiagram

            VStack(spacing: SnapSpacing.md) {
                connectionStep(icon: "wifi", text: "같은 Wi-Fi 네트워크에 연결")
                connectionStep(icon: "magnifyingglass", text: "자동으로 Mac을 검색")
                connectionStep(icon: "link", text: "탭하여 연결")
            }
        }
    }

    @ViewBuilder
    private var connectionDiagram: some View {
        HStack(spacing: SnapSpacing.xxl) {
            VStack(spacing: SnapSpacing.sm) {
                Image(systemName: "iphone")
                    .font(.system(size: 40))
                    .foregroundStyle(SnapColors.cyberBlue)
                Text("iPhone")
                    .font(SnapTypography.labelSmall)
                    .foregroundStyle(SnapColors.textSecondary)
            }

            VStack(spacing: SnapSpacing.xs) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 20))
                    .foregroundStyle(SnapColors.neonLime)
                Text("Wi-Fi")
                    .font(SnapTypography.caption)
                    .foregroundStyle(SnapColors.textTertiary)
            }

            VStack(spacing: SnapSpacing.sm) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 40))
                    .foregroundStyle(SnapColors.cyberBlue)
                Text("Mac")
                    .font(SnapTypography.labelSmall)
                    .foregroundStyle(SnapColors.textSecondary)
            }
        }
        .padding(SnapSpacing.xl)
        .background(SnapColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
    }

    @ViewBuilder
    private var permissionsContent: some View {
        VStack(spacing: SnapSpacing.lg) {
            permissionRow(
                icon: "hand.point.up.left.fill",
                title: "접근성",
                description: "Mac에서 커서와 키보드를 제어하기 위해 필요",
                isOnMac: true
            )

            permissionRow(
                icon: "network",
                title: "로컬 네트워크",
                description: "iPhone과 Mac 간의 연결을 위해 필요",
                isOnMac: false
            )
        }
    }

    @ViewBuilder
    private var completionContent: some View {
        VStack(spacing: SnapSpacing.xl) {
            VStack(spacing: SnapSpacing.md) {
                Text("모든 준비가 완료되었습니다!")
                    .font(SnapTypography.headlineMedium)
                    .foregroundStyle(SnapColors.textPrimary)

                Text("시작하기를 눌러 Snap을 사용해보세요")
                    .font(SnapTypography.bodyMedium)
                    .foregroundStyle(SnapColors.textSecondary)
            }

            VStack(spacing: SnapSpacing.sm) {
                checklistItem(text: "Snap Receiver가 Mac에서 실행 중인지 확인")
                checklistItem(text: "같은 Wi-Fi 네트워크에 연결되어 있는지 확인")
            }
            .padding(SnapSpacing.lg)
            .background(SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: SnapSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(SnapColors.neonLime)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: SnapSpacing.xxs) {
                Text(title)
                    .font(SnapTypography.labelLarge)
                    .foregroundStyle(SnapColors.textPrimary)

                Text(description)
                    .font(SnapTypography.bodySmall)
                    .foregroundStyle(SnapColors.textSecondary)
            }

            Spacer()
        }
        .padding(SnapSpacing.md)
        .background(SnapColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.sm))
    }

    @ViewBuilder
    private func featureCard(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: SnapSpacing.lg) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: SnapSpacing.xxs) {
                Text(title)
                    .font(SnapTypography.headlineSmall)
                    .foregroundStyle(SnapColors.textPrimary)

                Text(description)
                    .font(SnapTypography.bodySmall)
                    .foregroundStyle(SnapColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(SnapSpacing.md)
        .background(SnapColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
    }

    @ViewBuilder
    private func stepRow(number: Int, text: String) -> some View {
        HStack(spacing: SnapSpacing.md) {
            ZStack {
                Circle()
                    .fill(SnapColors.neonPink.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(SnapTypography.labelLarge)
                    .foregroundStyle(SnapColors.neonPink)
            }

            Text(text)
                .font(SnapTypography.bodyMedium)
                .foregroundStyle(SnapColors.textPrimary)

            Spacer()
        }
    }

    @ViewBuilder
    private func connectionStep(icon: String, text: String) -> some View {
        HStack(spacing: SnapSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(SnapColors.cyberBlue)
                .frame(width: 24)

            Text(text)
                .font(SnapTypography.bodyMedium)
                .foregroundStyle(SnapColors.textPrimary)

            Spacer()
        }
    }

    @ViewBuilder
    private func permissionRow(icon: String, title: String, description: String, isOnMac: Bool) -> some View {
        HStack(spacing: SnapSpacing.lg) {
            ZStack {
                Circle()
                    .fill(SnapColors.neonOrange.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(SnapColors.neonOrange)
            }

            VStack(alignment: .leading, spacing: SnapSpacing.xxs) {
                HStack(spacing: SnapSpacing.sm) {
                    Text(title)
                        .font(SnapTypography.headlineSmall)
                        .foregroundStyle(SnapColors.textPrimary)

                    Text(isOnMac ? "Mac" : "iPhone")
                        .font(SnapTypography.caption)
                        .foregroundStyle(SnapColors.textTertiary)
                        .padding(.horizontal, SnapSpacing.sm)
                        .padding(.vertical, SnapSpacing.xxs)
                        .background(SnapColors.backgroundTertiary)
                        .clipShape(Capsule())
                }

                Text(description)
                    .font(SnapTypography.bodySmall)
                    .foregroundStyle(SnapColors.textSecondary)
            }

            Spacer()
        }
        .padding(SnapSpacing.md)
        .background(SnapColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
    }

    @ViewBuilder
    private func checklistItem(text: String) -> some View {
        HStack(spacing: SnapSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(SnapColors.neonLime)

            Text(text)
                .font(SnapTypography.bodySmall)
                .foregroundStyle(SnapColors.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        },
        onComplete: {}
    )
}
