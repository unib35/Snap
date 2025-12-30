import ComposableArchitecture
import Shared

@Reducer
public struct ProductivityFeature {
    @ObservableState
    public struct State: Equatable {
        public var isSiriActive: Bool = false
    }

    public enum Action: Equatable, Sendable {
        // Siri
        case siriTapped
        case siriLongPressStarted
        case siriLongPressEnded
        case dictationTapped(String)
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            let client = connectionClient

            switch action {
            case .siriTapped:
                state.isSiriActive.toggle()
                let isActive = state.isSiriActive
                return .run { _ in
                    await client.sendSiriCommand(
                        isActive ? .activate : .deactivate,
                        ""
                    )
                }

            case .siriLongPressStarted:
                state.isSiriActive = true
                return .run { _ in
                    await client.sendSiriCommand(.activate, "")
                }

            case .siriLongPressEnded:
                state.isSiriActive = false
                return .run { _ in
                    await client.sendSiriCommand(.deactivate, "")
                }

            case .dictationTapped(let text):
                return .run { _ in
                    await client.sendSiriCommand(.dictation, text)
                }
            }
        }
    }
}
