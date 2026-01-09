import ComposableArchitecture
import Foundation
import Speech

/// TCA 의존성 클라이언트 - 음성 인식
public struct SpeechRecognizerClient: Sendable {
    public var requestAuthorization: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
    public var requestMicrophoneAuthorization: @Sendable () async -> Bool
    public var startRecognition: @Sendable () async -> AsyncStream<SpeechRecognitionEvent>
    public var stopRecognition: @Sendable () -> Void
}

// MARK: - Dependency Key

extension SpeechRecognizerClient: DependencyKey {
    public static var liveValue: SpeechRecognizerClient {
        let recognizer = LockIsolated(SpeechRecognizer())

        return SpeechRecognizerClient(
            requestAuthorization: {
                await recognizer.value.requestAuthorization()
            },
            requestMicrophoneAuthorization: {
                await recognizer.value.requestMicrophoneAuthorization()
            },
            startRecognition: {
                recognizer.value.startRecognition()
            },
            stopRecognition: {
                recognizer.value.stopRecognition()
            }
        )
    }

    public static var testValue: SpeechRecognizerClient {
        SpeechRecognizerClient(
            requestAuthorization: { .authorized },
            requestMicrophoneAuthorization: { true },
            startRecognition: { .finished },
            stopRecognition: {}
        )
    }
}

public extension DependencyValues {
    var speechRecognizerClient: SpeechRecognizerClient {
        get { self[SpeechRecognizerClient.self] }
        set { self[SpeechRecognizerClient.self] = newValue }
    }
}
