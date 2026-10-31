import ComposableArchitecture
import Foundation
import Speech
import UIKit

@Reducer
public struct VoiceTypingFeature {
    // MARK: - Language

    public enum Language: String, CaseIterable, Sendable {
        case system
        case korean
        case english

        public var title: String {
            switch self {
            case .system: return "기기 언어"
            case .korean: return "한국어"
            case .english: return "English"
            }
        }

        public var locale: Locale {
            switch self {
            case .system: return .current
            case .korean: return Locale(identifier: "ko-KR")
            case .english: return Locale(identifier: "en-US")
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var isRecording: Bool = false
        public var recognizedText: String = ""
        public var authorizationStatus: AuthorizationStatus = .notDetermined
        @Shared(.appStorage("snapVoiceTypingLanguage")) public var language: Language = .system
        @Presents public var alert: AlertState<Action.Alert>?

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
        case setLanguage(Language)
        case alert(PresentationAction<Alert>)

        @CasePathable
        public enum Alert: Equatable, Sendable {
            case dismiss
            case openSettings
        }
    }

    @Dependency(\.connectionClient) var connectionClient
    @Dependency(\.speechRecognizerClient) var speechRecognizerClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.checkAuthorization)

            case .checkAuthorization:
                return .run { [speechRecognizerClient] send in
                    let speechStatus = await speechRecognizerClient.requestAuthorization()
                    let micStatus = await speechRecognizerClient.requestMicrophoneAuthorization()

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
                    state.alert = AppError.permission(.speechRecognition)
                        .toAlertState(dismiss: .dismiss, openSettings: .openSettings)
                    return .none
                }

                let locale = state.language.locale
                guard speechRecognizerClient.isLocaleSupported(locale) else {
                    state.alert = AppError.speech(.languageNotSupported)
                        .toSimpleAlertState(dismiss: .dismiss)
                    return .none
                }

                state.isRecording = true
                state.recognizedText = ""

                return .run { [speechRecognizerClient] send in
                    for await event in await speechRecognizerClient.startRecognition(locale) {
                        await send(.recognitionEvent(event))
                    }
                }

            case .stopRecording:
                state.isRecording = false
                speechRecognizerClient.stopRecognition()
                return .none

            case .recognitionEvent(let event):
                switch event {
                case .recognized(let text, let isFinal):
                    state.recognizedText = text
                    if isFinal {
                        state.isRecording = false
                    }

                case .error(let message):
                    state.alert = AppError.general(message)
                        .toSimpleAlertState(dismiss: .dismiss)
                    state.isRecording = false

                case .availabilityChanged(let available):
                    if !available {
                        state.alert = AppError.speech(.notAvailable)
                            .toSimpleAlertState(dismiss: .dismiss)
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

            case .setLanguage(let language):
                guard language != state.language else { return .none }
                guard speechRecognizerClient.isLocaleSupported(language.locale) else {
                    state.alert = AppError.speech(.languageNotSupported)
                        .toSimpleAlertState(dismiss: .dismiss)
                    return .none
                }
                state.$language.withLock { $0 = language }
                // 녹음 중이면 이전 언어 인식을 멈추고 새 언어로 다시 시작하게 함
                guard state.isRecording else { return .none }
                return .send(.stopRecording)

            case .alert(.presented(.openSettings)):
                return .run { _ in
                    await MainActor.run {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
