import AppKit
import Foundation
import Shared

/// 시스템 명령 컨트롤러
/// Mac 시스템 제어 명령을 실행합니다.
@MainActor
public final class SystemController {
    public static let shared = SystemController()

    private init() {}

    // MARK: - Public Methods

    /// 시스템 명령 실행
    public func execute(command: SystemCommand.Command) {
        switch command {
        case .sleep:
            sleep()
        case .lock:
            lock()
        case .logout:
            logout()
        case .restart:
            restart()
        case .shutdown:
            shutdown()
        }
    }

    // MARK: - Sleep

    /// Mac 잠자기
    private func sleep() {
        let script = """
            tell application "System Events" to sleep
        """
        runAppleScript(script)
    }

    // MARK: - Lock Screen

    /// 화면 잠금
    private func lock() {
        // CGSession을 사용한 화면 잠금
        // 이 방법이 가장 빠르고 안정적입니다
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]

        do {
            try task.run()
        } catch {
            // fallback: AppleScript 사용
            let script = """
                tell application "System Events" to keystroke "q" using {control down, command down}
            """
            runAppleScript(script)
        }
    }

    // MARK: - Logout

    /// 로그아웃
    private func logout() {
        let script = """
            tell application "System Events"
                log out
            end tell
        """
        runAppleScript(script)
    }

    // MARK: - Restart

    /// 재시작
    private func restart() {
        let script = """
            tell application "System Events"
                restart
            end tell
        """
        runAppleScript(script)
    }

    // MARK: - Shutdown

    /// 종료
    private func shutdown() {
        let script = """
            tell application "System Events"
                shut down
            end tell
        """
        runAppleScript(script)
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
