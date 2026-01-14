import ComposableArchitecture
import Foundation

// MARK: - Onboarding Client

public struct OnboardingClient: Sendable {
    public var hasCompletedOnboarding: @Sendable () -> Bool
    public var setOnboardingCompleted: @Sendable (Bool) -> Void
}

extension OnboardingClient: DependencyKey {
    public static var liveValue: OnboardingClient {
        OnboardingClient(
            hasCompletedOnboarding: {
                UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            },
            setOnboardingCompleted: { completed in
                UserDefaults.standard.set(completed, forKey: "hasCompletedOnboarding")
            }
        )
    }

    public static var testValue: OnboardingClient {
        OnboardingClient(
            hasCompletedOnboarding: { false },
            setOnboardingCompleted: { _ in }
        )
    }
}

public extension DependencyValues {
    var onboardingClient: OnboardingClient {
        get { self[OnboardingClient.self] }
        set { self[OnboardingClient.self] = newValue }
    }
}

// MARK: - Onboarding Page

public enum OnboardingPage: Int, CaseIterable, Sendable {
    case welcome = 0
    case features
    case macReceiver
    case connection
    case permissions
    case completion

    public var title: String {
        switch self {
        case .welcome:
            return "Snap에 오신 것을 환영합니다"
        case .features:
            return "주요 기능"
        case .macReceiver:
            return "Mac Receiver 설치"
        case .connection:
            return "연결 방법"
        case .permissions:
            return "권한 안내"
        case .completion:
            return "준비 완료"
        }
    }

    public var subtitle: String {
        switch self {
        case .welcome:
            return "iPhone으로 Mac을 원격 제어하세요"
        case .features:
            return "트랙패드, 키보드, 미디어 컨트롤"
        case .macReceiver:
            return "Mac에서 Receiver 앱을 설치하세요"
        case .connection:
            return "같은 Wi-Fi에서 자동으로 연결됩니다"
        case .permissions:
            return "원활한 사용을 위해 필요한 권한"
        case .completion:
            return "이제 Snap을 사용할 준비가 되었습니다"
        }
    }

    public var icon: String {
        switch self {
        case .welcome:
            return "hand.wave.fill"
        case .features:
            return "sparkles"
        case .macReceiver:
            return "desktopcomputer"
        case .connection:
            return "wifi"
        case .permissions:
            return "checkmark.shield.fill"
        case .completion:
            return "checkmark.circle.fill"
        }
    }

    public var isLast: Bool {
        self == .completion
    }

    public var isFirst: Bool {
        self == .welcome
    }
}

// MARK: - OnboardingFeature

@Reducer
public struct OnboardingFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var currentPage: OnboardingPage = .welcome
        public var isAnimating: Bool = false

        public init(currentPage: OnboardingPage = .welcome) {
            self.currentPage = currentPage
        }

        public var progress: Double {
            Double(currentPage.rawValue) / Double(OnboardingPage.allCases.count - 1)
        }

        public var canGoBack: Bool {
            !currentPage.isFirst
        }

        public var canGoNext: Bool {
            !currentPage.isLast
        }
    }

    public enum Action: Equatable, Sendable {
        case onAppear
        case nextPage
        case previousPage
        case goToPage(OnboardingPage)
        case skipOnboarding
        case completeOnboarding
        case animationCompleted
    }

    @Dependency(\.onboardingClient) var onboardingClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none

            case .nextPage:
                guard let nextIndex = OnboardingPage.allCases.firstIndex(of: state.currentPage),
                      nextIndex + 1 < OnboardingPage.allCases.count else {
                    return .none
                }
                state.isAnimating = true
                state.currentPage = OnboardingPage.allCases[nextIndex + 1]
                return .run { send in
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.animationCompleted)
                }

            case .previousPage:
                guard let currentIndex = OnboardingPage.allCases.firstIndex(of: state.currentPage),
                      currentIndex > 0 else {
                    return .none
                }
                state.isAnimating = true
                state.currentPage = OnboardingPage.allCases[currentIndex - 1]
                return .run { send in
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.animationCompleted)
                }

            case .goToPage(let page):
                state.isAnimating = true
                state.currentPage = page
                return .run { send in
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.animationCompleted)
                }

            case .skipOnboarding:
                return .send(.completeOnboarding)

            case .completeOnboarding:
                let client = onboardingClient
                return .run { _ in
                    client.setOnboardingCompleted(true)
                }

            case .animationCompleted:
                state.isAnimating = false
                return .none
            }
        }
    }
}
