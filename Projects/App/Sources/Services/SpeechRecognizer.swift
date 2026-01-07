import Foundation
import Speech
import AVFoundation

/// 음성 인식 결과 이벤트
public enum SpeechRecognitionEvent: Equatable, Sendable {
    case recognized(text: String, isFinal: Bool)
    case error(String)
    case availabilityChanged(Bool)
}

/// 음성 인식 서비스
///
/// - Note: `@unchecked Sendable` - SFSpeechRecognizer와 AVAudioEngine은 내부적으로 스레드 안전하게 관리됨
public final class SpeechRecognizer: @unchecked Sendable {
    // MARK: - Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var isRecording = false

    // MARK: - Initialization

    public init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Authorization

    /// 음성 인식 권한 요청
    public func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// 마이크 권한 요청
    public func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// 현재 권한 상태
    public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    /// 음성 인식 사용 가능 여부
    public var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }

    // MARK: - Recognition

    /// 음성 인식 시작
    public func startRecognition() -> AsyncStream<SpeechRecognitionEvent> {
        AsyncStream { continuation in
            do {
                try self.startRecognitionInternal(continuation: continuation)

                continuation.onTermination = { [weak self] _ in
                    self?.stopRecognition()
                }
            } catch {
                continuation.yield(.error(error.localizedDescription))
                continuation.finish()
            }
        }
    }

    /// 음성 인식 중지
    public func stopRecognition() {
        guard isRecording else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    // MARK: - Private

    private func startRecognitionInternal(continuation: AsyncStream<SpeechRecognitionEvent>.Continuation) throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognizerError.notAvailable
        }

        guard !isRecording else {
            throw SpeechRecognizerError.alreadyRecording
        }

        // 기존 태스크 정리
        recognitionTask?.cancel()
        recognitionTask = nil

        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // 인식 요청 생성
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognizerError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // 인식 태스크 시작
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard self != nil else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                continuation.yield(.recognized(text: text, isFinal: isFinal))

                if isFinal {
                    continuation.finish()
                }
            }

            if let error = error {
                continuation.yield(.error(error.localizedDescription))
                continuation.finish()
            }
        }

        // 오디오 입력 설정
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }
}

// MARK: - Errors

public enum SpeechRecognizerError: LocalizedError {
    case notAvailable
    case alreadyRecording
    case requestCreationFailed
    case audioEngineError

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "음성 인식을 사용할 수 없습니다"
        case .alreadyRecording:
            return "이미 녹음 중입니다"
        case .requestCreationFailed:
            return "음성 인식 요청을 생성할 수 없습니다"
        case .audioEngineError:
            return "오디오 엔진 오류가 발생했습니다"
        }
    }
}
