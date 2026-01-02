import AppKit
import Foundation
import Shared

/// Siri 컨트롤러
/// AppleScript를 사용하여 Siri를 제어합니다.
@MainActor
public final class SiriController {
    public static let shared = SiriController()

    private init() {}

    // MARK: - Public Methods

    /// Siri 명령 실행
    public func execute(command: SiriCommand) {
        switch command.action {
        case .activate:
            activateSiri()
        case .deactivate:
            deactivateSiri()
        case .dictation:
            startDictation(text: command.text)
        }
    }

    // MARK: - Siri Control

    /// Siri 활성화
    private func activateSiri() {
        let script = """
            tell application "Siri" to activate
        """
        runAppleScript(script)
    }

    /// Siri 비활성화
    private func deactivateSiri() {
        // Escape 키를 눌러 Siri 종료
        sendKeyEvent(keyCode: 53) // Escape

        // 또는 AppleScript로 Siri 종료
        let script = """
            tell application "Siri" to quit
        """
        runAppleScript(script)
    }

    /// 받아쓰기 모드 시작
    private func startDictation(text: String) {
        // fn 키를 두 번 눌러 받아쓰기 활성화
        // macOS에서 받아쓰기는 fn fn (두 번 연속)으로 활성화됩니다
        // 키 코드: fn = 63

        // fn key down
        sendKeyEvent(keyCode: 63, keyDown: true)
        sendKeyEvent(keyCode: 63, keyDown: false)

        // 짧은 딜레이 후 다시 fn
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.sendKeyEvent(keyCode: 63, keyDown: true)
            self?.sendKeyEvent(keyCode: 63, keyDown: false)
        }

        // 텍스트가 있으면 타이핑 (받아쓰기 대신 직접 입력)
        if !text.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.typeText(text)
            }
        }
    }

    // MARK: - Key Event Helper

    private func sendKeyEvent(keyCode: CGKeyCode, keyDown: Bool = true) {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
        event?.post(tap: .cghidEventTap)

        if keyDown {
            // Key up
            let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
            upEvent?.post(tap: .cghidEventTap)
        }
    }

    /// 텍스트 직접 타이핑
    private func typeText(_ text: String) {
        for character in text {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            var char = UniChar(character.utf16.first ?? 0)
            event?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
            event?.post(tap: .cghidEventTap)

            let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            upEvent?.post(tap: .cghidEventTap)
        }
    }

    // MARK: - AppleScript Helper

    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            let output = script.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }
}
