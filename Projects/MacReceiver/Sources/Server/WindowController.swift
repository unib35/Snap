import AppKit
import ApplicationServices
import Foundation
import Shared

/// 윈도우 컨트롤러
/// AXUIElement를 사용하여 윈도우 크기/위치를 제어합니다.
@MainActor
public final class WindowController {
    public static let shared = WindowController()

    private init() {}

    // MARK: - Public Methods

    /// 윈도우 스냅 실행
    public func snap(to position: WindowSnap.Position) {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let window = getFocusedWindow(for: frontmostApp) else {
            return
        }

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        let targetFrame = calculateFrame(for: position, in: screenFrame)
        setWindowFrame(window, to: targetFrame)
    }

    // MARK: - Private Methods

    /// 앱의 포커스된 윈도우 가져오기
    private func getFocusedWindow(for app: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )

        guard result == .success, let window = focusedWindow else {
            // 포커스된 윈도우가 없으면 첫 번째 윈도우 시도
            return getFirstWindow(for: appElement)
        }

        return (window as! AXUIElement)
    }

    /// 첫 번째 윈도우 가져오기
    private func getFirstWindow(for appElement: AXUIElement) -> AXUIElement? {
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowList
        )

        guard result == .success,
              let windows = windowList as? [AXUIElement],
              let firstWindow = windows.first else {
            return nil
        }

        return firstWindow
    }

    /// 포지션에 따른 프레임 계산
    private func calculateFrame(for position: WindowSnap.Position, in screenFrame: CGRect) -> CGRect {
        let x = screenFrame.origin.x
        let y = screenFrame.origin.y
        let width = screenFrame.width
        let height = screenFrame.height

        switch position {
        case .fullScreen:
            return screenFrame

        case .leftHalf:
            return CGRect(x: x, y: y, width: width / 2, height: height)

        case .rightHalf:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height)

        case .topHalf:
            return CGRect(x: x, y: y + height / 2, width: width, height: height / 2)

        case .bottomHalf:
            return CGRect(x: x, y: y, width: width, height: height / 2)

        case .center:
            let centerWidth = width * 0.6
            let centerHeight = height * 0.7
            return CGRect(
                x: x + (width - centerWidth) / 2,
                y: y + (height - centerHeight) / 2,
                width: centerWidth,
                height: centerHeight
            )

        case .topLeft:
            return CGRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)

        case .topRight:
            return CGRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)

        case .bottomLeft:
            return CGRect(x: x, y: y, width: width / 2, height: height / 2)

        case .bottomRight:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height / 2)
        }
    }

    /// 윈도우 프레임 설정
    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) {
        // 위치 설정
        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }

        // 크기 설정
        var size = CGSize(width: frame.width, height: frame.height)
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    // MARK: - Window Info

    /// 현재 윈도우 정보
    public struct WindowInfo: Sendable {
        public let title: String
        public let appName: String
        public let frame: CGRect
    }

    /// 현재 포커스된 윈도우 정보 가져오기
    public func getFocusedWindowInfo() -> WindowInfo? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let window = getFocusedWindow(for: frontmostApp) else {
            return nil
        }

        let title = getWindowTitle(window) ?? "Unknown"
        let appName = frontmostApp.localizedName ?? "Unknown"
        let frame = getWindowFrame(window) ?? .zero

        return WindowInfo(title: title, appName: appName, frame: frame)
    }

    /// 윈도우 타이틀 가져오기
    private func getWindowTitle(_ window: AXUIElement) -> String? {
        var titleValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            window,
            kAXTitleAttribute as CFString,
            &titleValue
        )

        guard result == .success, let title = titleValue as? String else {
            return nil
        }

        return title
    }

    /// 윈도우 프레임 가져오기
    private func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)

        guard let posVal = positionValue, let sizeVal = sizeValue else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero

        AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)

        return CGRect(origin: position, size: size)
    }
}
