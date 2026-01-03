import ComposableArchitecture
import Foundation
import Speech

@Reducer
public struct VoiceTypingFeature {
    @ObservableState
    public struct State: Equatable {
        public var isRecording: Bool = false
        public var recognizedText: String = ""
        public var authorizationStatus: AuthorizationStatus = .notDetermined
        public var errorMessage: String?

        public enum AuthorizationStatus: Equatable, Sendable {
            case notDetermined
            case authorized
            case denied
            case restricted
        }

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case onAppear
        case checkAuthorization
        case authorizationResult(State.AuthorizationStatus)
        case toggleRecording
        case startRecording
        case stopRecording
        case recognitionEvent(SpeechRecognitionEvent)
        case sendText
        case clearText
        case dismissError
    }

    @Dependency(\.connectionClient) var connectionClient

    private let speechRecognizer = SpeechRecognizer()

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.checkAuthorization)

            case .checkAuthorization:
                let recognizer = speechRecognizer
                return .run { send in
                    let speechStatus = await recognizer.requestAuthorization()
                    let micStatus = await recognizer.requestMicrophoneAuthorization()

                    let status: State.AuthorizationStatus
                    if !micStatus {
                        status = .denied
                    } else {
                        switch speechStatus {
                        case .authorized:
                            status = .authorized
                        case .denied:
                            status = .denied
                        case .restricted:
                            status = .restricted
                        case .notDetermined:
                            status = .notDetermined
                        @unknown default:
                            status = .denied
                        }
                    }
                    await send(.authorizationResult(status))
                }

            case .authorizationResult(let status):
                state.authorizationStatus = status
                return .none

            case .toggleRecording:
                if state.isRecording {
                    return .send(.stopRecording)
                } else {
                    return .send(.startRecording)
                }

            case .startRecording:
                guard state.authorizationStatus == .authorized else {
                    state.errorMessage = "음성 인식 권한이 필요합니다"
                    return .none
                }

                state.isRecording = true
                state.recognizedText = ""
                state.errorMessage = nil

                let recognizer = speechRecognizer
                return .run { send in
                    for await event in recognizer.startRecognition() {
                        await send(.recognitionEvent(event))
                    }
                }

            case .stopRecording:
                state.isRecording = false
                speechRecognizer.stopRecognition()
                return .none

            case .recognitionEvent(let event):
                switch event {
                case .recognized(let text, let isFinal):
                    state.recognizedText = text
                    if isFinal {
                        state.isRecording = false
                    }

                case .error(let message):
                    state.errorMessage = message
                    state.isRecording = false

                case .availabilityChanged(let available):
                    if !available {
                        state.errorMessage = "음성 인식을 사용할 수 없습니다"
                        state.isRecording = false
                    }
                }
                return .none

            case .sendText:
                guard !state.recognizedText.isEmpty else { return .none }

                let text = state.recognizedText
                let client = connectionClient

                return .run { _ in
                    await client.sendVoiceText(text, true)
                }

            case .clearText:
                state.recognizedText = ""
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}
