import Foundation

// MARK: - App Error

/// 앱 전역 에러 타입
public enum AppError: Equatable, Sendable, LocalizedError {
    case connection(ConnectionErrorType)
    case permission(PermissionErrorType)
    case speech(SpeechErrorType)
    case general(String)

    // MARK: - Error Types

    public enum ConnectionErrorType: Equatable, Sendable {
        case discoveryFailed
        case connectionFailed
        case connectionLost
        case timeout
        case pairingFailed
        case serverError(String)
    }

    public enum PermissionErrorType: Equatable, Sendable {
        case speechRecognition
        case microphone
        case accessibility
    }

    public enum SpeechErrorType: Equatable, Sendable {
        case notAvailable
        case alreadyRecording
        case requestCreationFailed
        case audioEngineError
    }

    // MARK: - User Friendly Message

    public var userMessage: String {
        switch self {
        case .connection(let type):
            return type.message
        case .permission(let type):
            return type.message
        case .speech(let type):
            return type.message
        case .general(let message):
            return message
        }
    }

    public var title: String {
        switch self {
        case .connection:
            return "연결 오류"
        case .permission:
            return "권한 필요"
        case .speech:
            return "음성 인식 오류"
        case .general:
            return "오류"
        }
    }

    public var errorDescription: String? {
        userMessage
    }

    // MARK: - Retry Availability

    public var canRetry: Bool {
        switch self {
        case .connection(let type):
            switch type {
            case .discoveryFailed, .connectionFailed, .timeout, .pairingFailed:
                return true
            case .connectionLost, .serverError:
                return false
            }
        case .permission:
            return false
        case .speech(let type):
            switch type {
            case .notAvailable, .alreadyRecording:
                return false
            case .requestCreationFailed, .audioEngineError:
                return true
            }
        case .general:
            return false
        }
    }

    // MARK: - Settings Navigation

    public var shouldOpenSettings: Bool {
        if case .permission = self {
            return true
        }
        return false
    }
}

// MARK: - Connection Error Type Messages

extension AppError.ConnectionErrorType {
    var message: String {
        switch self {
        case .discoveryFailed:
            return "Mac을 찾을 수 없습니다. 동일한 네트워크에 연결되어 있는지 확인해주세요."
        case .connectionFailed:
            return "Mac에 연결할 수 없습니다. Mac에서 Snap Receiver가 실행 중인지 확인해주세요."
        case .connectionLost:
            return "연결이 끊어졌습니다. 네트워크 상태를 확인해주세요."
        case .timeout:
            return "연결 시간이 초과되었습니다. 다시 시도해주세요."
        case .pairingFailed:
            return "페어링에 실패했습니다. PIN 코드를 다시 확인해주세요."
        case .serverError(let detail):
            return "서버 오류: \(detail)"
        }
    }
}

// MARK: - Permission Error Type Messages

extension AppError.PermissionErrorType {
    var message: String {
        switch self {
        case .speechRecognition:
            return "음성 인식 권한이 필요합니다. 설정에서 권한을 허용해주세요."
        case .microphone:
            return "마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요."
        case .accessibility:
            return "접근성 권한이 필요합니다. Mac 시스템 환경설정에서 권한을 허용해주세요."
        }
    }
}

// MARK: - Speech Error Type Messages

extension AppError.SpeechErrorType {
    var message: String {
        switch self {
        case .notAvailable:
            return "음성 인식을 사용할 수 없습니다."
        case .alreadyRecording:
            return "이미 녹음 중입니다."
        case .requestCreationFailed:
            return "음성 인식 요청을 생성할 수 없습니다."
        case .audioEngineError:
            return "오디오 엔진 오류가 발생했습니다."
        }
    }
}
