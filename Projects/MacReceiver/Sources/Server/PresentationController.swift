import AppKit
import Foundation
import Shared

/// 발표 컨트롤러
/// 앞에 있는 발표 앱에 맞는 단축키로 발표 명령을 실행합니다.
@MainActor
public final class PresentationController {
    public static let shared = PresentationController()

    /// 발표 명령 하나를 실행하는 키 조합
    struct Shortcut: Equatable {
        let keyCode: CGKeyCode
        let modifiers: CGEventFlags

        init(_ keyCode: CGKeyCode, _ modifiers: CGEventFlags = []) {
            self.keyCode = keyCode
            self.modifiers = modifiers
        }
    }

    /// 단축키가 다른 발표 앱
    enum App: Equatable {
        case keynote
        case powerPoint
        /// Google Slides 등 브라우저에서 여는 발표
        case browser
        case other

        private static let browserBundleIDs: Set<String> = [
            "com.apple.Safari",
            "com.google.Chrome",
            "company.thebrowser.Browser",
            "com.microsoft.edgemac",
            "org.mozilla.firefox",
            "com.brave.Browser",
            "com.naver.Whale",
        ]

        init(bundleID: String?) {
            switch bundleID {
            case "com.apple.iWork.Keynote":
                self = .keynote
            case "com.microsoft.Powerpoint":
                self = .powerPoint
            case let id? where Self.browserBundleIDs.contains(id):
                self = .browser
            default:
                self = .other
            }
        }
    }

    // MARK: - Key Codes

    private enum KeyCode {
        static let leftArrow: CGKeyCode = 123
        static let rightArrow: CGKeyCode = 124
        static let escape: CGKeyCode = 53
        static let returnKey: CGKeyCode = 36
        static let bKey: CGKeyCode = 11
        static let pKey: CGKeyCode = 35
    }

    private let postEvent: (CGEvent) -> Void
    private let frontmostBundleID: () -> String?

    init(
        postEvent: @escaping (CGEvent) -> Void = { $0.post(tap: .cghidEventTap) },
        frontmostBundleID: @escaping () -> String? = { NSWorkspace.shared.frontmostApplication?.bundleIdentifier }
    ) {
        self.postEvent = postEvent
        self.frontmostBundleID = frontmostBundleID
    }

    // MARK: - Public Methods

    /// 발표 명령 실행
    /// - Returns: 실행할 단축키가 있어 키를 보냈으면 true
    @discardableResult
    public func execute(command: Presentation.Command) -> Bool {
        guard let shortcut = Self.shortcut(for: command, in: App(bundleID: frontmostBundleID())) else {
            return false
        }
        sendKeyEvent(shortcut)
        return true
    }

    /// 앱별 발표 단축키
    /// 시작 단축키를 모르는 앱에서는 시작 명령을 보내지 않습니다.
    static func shortcut(for command: Presentation.Command, in app: App) -> Shortcut? {
        switch command {
        case .nextSlide:
            return Shortcut(KeyCode.rightArrow)
        case .prevSlide:
            return Shortcut(KeyCode.leftArrow)
        case .end:
            return Shortcut(KeyCode.escape)
        case .blankScreen:
            // Keynote, PowerPoint, Google Slides 모두 B로 검은 화면을 켜고 끕니다.
            return Shortcut(KeyCode.bKey)
        case .start:
            switch app {
            case .keynote:
                return Shortcut(KeyCode.pKey, [.maskCommand, .maskAlternate])
            case .powerPoint:
                return Shortcut(KeyCode.returnKey, [.maskCommand, .maskShift])
            case .browser:
                return Shortcut(KeyCode.returnKey, .maskCommand)
            case .other:
                return nil
            }
        }
    }

    // MARK: - Key Event Helpers

    private func sendKeyEvent(_ shortcut: Shortcut) {
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: shortcut.keyCode, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: shortcut.keyCode, keyDown: false) else {
            return
        }

        keyDownEvent.flags = shortcut.modifiers
        keyUpEvent.flags = shortcut.modifiers

        postEvent(keyDownEvent)
        postEvent(keyUpEvent)
    }
}
