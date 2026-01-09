import ComposableArchitecture
import Foundation
import Speech
import UIKit

@Reducer
public struct VoiceTypingFeature {
    @ObservableState
    public struct State: Equatable {
        public var isRecording: Bool = false
        public var recognizedText: String = ""
        public var authorizationStatus: AuthorizationStatus = .notDetermined
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
                    state.alert = AlertState {
                        TextState("권한 필요")
                    } actions: {
                        ButtonState(action: .openSettings) {
                            TextState("설정 열기")
                        }
                        ButtonState(role: .cancel, action: .dismiss) {
                            TextState("취소")
                        }
                    } message: {
                        TextState("음성 인식 권한이 필요합니다. 설정에서 권한을 허용해주세요.")
                    }
                    return .none
                }

                state.isRecording = true
                state.recognizedText = ""

                return .run { [speechRecognizerClient] send in
                    for await event in await speechRecognizerClient.startRecognition() {
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
                    state.alert = AlertState {
                        TextState("오류")
                    } actions: {
                        ButtonState(action: .dismiss) {
                            TextState("확인")
                        }
                    } message: {
                        TextState(message)
                    }
                    state.isRecording = false

                case .availabilityChanged(let available):
                    if !available {
                        state.alert = AlertState {
                            TextState("오류")
                        } actions: {
                            ButtonState(action: .dismiss) {
                                TextState("확인")
                            }
                        } message: {
                            TextState("음성 인식을 사용할 수 없습니다")
                        }
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
