import ComposableArchitecture

/// TCA용 AppError AlertState 변환 유틸리티
public extension AppError {
    /// AppError를 TCA AlertState로 변환
    func toAlertState<AlertAction: Equatable>(
        dismiss: AlertAction,
        retry: AlertAction? = nil,
        openSettings: AlertAction? = nil
    ) -> AlertState<AlertAction> {
        var buttons: [ButtonState<AlertAction>] = []

        // 재시도 버튼 (가능한 경우)
        if canRetry, let retry {
            buttons.append(
                ButtonState(action: retry) {
                    TextState("다시 시도")
                }
            )
        }

        // 설정 열기 버튼 (권한 에러인 경우)
        if shouldOpenSettings, let openSettings {
            buttons.append(
                ButtonState(action: openSettings) {
                    TextState("설정 열기")
                }
            )
        }

        // 닫기 버튼 (항상 포함)
        buttons.append(
            ButtonState(role: .cancel, action: dismiss) {
                TextState("확인")
            }
        )

        return AlertState {
            TextState(title)
        } actions: {
            for button in buttons {
                button
            }
        } message: {
            TextState(userMessage)
        }
    }

    /// 간단한 에러 Alert (닫기만 가능)
    func toSimpleAlertState<AlertAction: Equatable>(
        dismiss: AlertAction
    ) -> AlertState<AlertAction> {
        AlertState {
            TextState(title)
        } actions: {
            ButtonState(role: .cancel, action: dismiss) {
                TextState("확인")
            }
        } message: {
            TextState(userMessage)
        }
    }
}

/// ConnectionError를 AppError로 변환
public extension ConnectionError {
    /// ConnectionError를 AppError로 변환
    var toAppError: AppError {
        switch self {
        case .discoveryFailed:
            return .connection(.discoveryFailed)
        case .connectionFailed:
            return .connection(.connectionFailed)
        case .connectionLost:
            return .connection(.connectionLost)
        case .timeout:
            return .connection(.timeout)
        case .pairingFailed:
            return .connection(.pairingFailed)
        case .serverError(let detail), .protocolError(let detail):
            return .connection(.serverError(detail))
        case .disconnected:
            return .connection(.connectionLost)
        }
    }
}

/// 공통 에러 Alert Action 프로토콜
public protocol ErrorAlertAction: Equatable {
    static var dismissError: Self { get }
    static var retryError: Self? { get }
    static var openSettings: Self? { get }
}

public extension ErrorAlertAction {
    static var retryError: Self? { nil }
    static var openSettings: Self? { nil }
}
