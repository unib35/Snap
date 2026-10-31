import ComposableArchitecture
import Foundation
import Testing
@testable import App

@Suite("음성 인식 언어 테스트")
struct VoiceTypingLanguageTests {
    @Test("녹음 시작 시 선택한 언어로 인식")
    func startRecordingUsesSelectedLanguage() async {
        let locales = LockIsolated<[String]>([])
        var state = VoiceTypingFeature.State()
        state.authorizationStatus = .authorized
        state.$language.withLock { $0 = .english }

        let store = await TestStore(initialState: state) {
            VoiceTypingFeature()
        } withDependencies: {
            $0.speechRecognizerClient.startRecognition = { locale in
                locales.withValue { $0.append(locale.identifier) }
                return .finished
            }
        }

        await store.send(.startRecording) {
            $0.isRecording = true
        }
        await store.finish()

        #expect(locales.value == ["en-US"])
    }

    @Test("지원하지 않는 언어면 녹음을 시작하지 않고 안내")
    func unsupportedLanguageBlocksRecording() async {
        var state = VoiceTypingFeature.State()
        state.authorizationStatus = .authorized

        let store = await TestStore(initialState: state) {
            VoiceTypingFeature()
        } withDependencies: {
            $0.speechRecognizerClient.isLocaleSupported = { _ in false }
        }

        await store.send(.startRecording) {
            $0.alert = AppError.speech(.languageNotSupported).toSimpleAlertState(dismiss: .dismiss)
        }
    }

    @Test("언어를 바꾸면 선택값을 저장")
    func setLanguageSavesSelection() async {
        let store = await TestStore(initialState: VoiceTypingFeature.State()) {
            VoiceTypingFeature()
        }

        await store.send(.setLanguage(.korean)) {
            $0.$language.withLock { $0 = .korean }
        }
    }

    @Test("지원하지 않는 언어로는 바꾸지 않고 안내")
    func setUnsupportedLanguageKeepsSelection() async {
        let store = await TestStore(initialState: VoiceTypingFeature.State()) {
            VoiceTypingFeature()
        } withDependencies: {
            $0.speechRecognizerClient.isLocaleSupported = { _ in false }
        }

        await store.send(.setLanguage(.english)) {
            $0.alert = AppError.speech(.languageNotSupported).toSimpleAlertState(dismiss: .dismiss)
        }
    }

    @Test("녹음 중 언어를 바꾸면 녹음을 멈춤")
    func setLanguageWhileRecordingStops() async {
        let stopped = LockIsolated(false)
        var state = VoiceTypingFeature.State()
        state.isRecording = true

        let store = await TestStore(initialState: state) {
            VoiceTypingFeature()
        } withDependencies: {
            $0.speechRecognizerClient.stopRecognition = { stopped.setValue(true) }
        }

        await store.send(.setLanguage(.english)) {
            $0.$language.withLock { $0 = .english }
        }
        await store.receive(.stopRecording) {
            $0.isRecording = false
        }

        #expect(stopped.value)
    }
}
