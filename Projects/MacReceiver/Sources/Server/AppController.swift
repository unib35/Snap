import AppKit
import Foundation
import Shared

/// 앱 컨트롤러
/// NSWorkspace를 사용하여 앱 관리 및 스위칭 기능을 제공합니다.
@MainActor
public final class AppController {
    public static let shared = AppController()

    private let workspace = NSWorkspace.shared
    private let iconSize: CGFloat = 64

    private init() {}

    // MARK: - Public Methods

    /// 실행 중인 앱 목록 조회
    public func getRunningApps() -> [AppInfo] {
        let runningApps = workspace.runningApplications

        return runningApps.compactMap { app -> AppInfo? in
            // 일반 앱만 포함 (백그라운드 앱 제외)
            guard app.activationPolicy == .regular else { return nil }
            guard let bundleID = app.bundleIdentifier else { return nil }
            guard let name = app.localizedName else { return nil }

            let iconData = extractIconData(for: app)

            return AppInfo(
                bundleID: bundleID,
                name: name,
                iconData: iconData,
                isActive: app.isActive,
                pid: UInt32(app.processIdentifier)
            )
        }
    }

    /// 앱 포커스 전환
    public func focusApp(bundleID: String, pid: UInt32) -> Bool {
        // PID로 먼저 시도
        if pid > 0 {
            let runningApps = workspace.runningApplications
            if let app = runningApps.first(where: { $0.processIdentifier == pid_t(pid) }) {
                return app.activate()
            }
        }

        // BundleID로 시도
        let runningApps = workspace.runningApplications
        if let app = runningApps.first(where: { $0.bundleIdentifier == bundleID }) {
            return app.activate()
        }

        return false
    }

    /// 앱 실행
    public func launchApp(bundleID: String) -> Bool {
        guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) else {
            return false
        }

        workspace.open(appURL)
        return true
    }

    /// 앱 종료
    public func terminateApp(bundleID: String, pid: UInt32) -> Bool {
        let runningApps = workspace.runningApplications

        // PID로 먼저 시도
        if pid > 0 {
            if let app = runningApps.first(where: { $0.processIdentifier == pid_t(pid) }) {
                return app.terminate()
            }
        }

        // BundleID로 시도
        if let app = runningApps.first(where: { $0.bundleIdentifier == bundleID }) {
            return app.terminate()
        }

        return false
    }

    /// 앱 강제 종료
    public func forceTerminateApp(bundleID: String, pid: UInt32) -> Bool {
        let runningApps = workspace.runningApplications

        // PID로 먼저 시도
        if pid > 0 {
            if let app = runningApps.first(where: { $0.processIdentifier == pid_t(pid) }) {
                return app.forceTerminate()
            }
        }

        // BundleID로 시도
        if let app = runningApps.first(where: { $0.bundleIdentifier == bundleID }) {
            return app.forceTerminate()
        }

        return false
    }

    /// 현재 활성 앱 정보
    public func getActiveApp() -> AppInfo? {
        guard let frontApp = workspace.frontmostApplication else { return nil }
        guard let bundleID = frontApp.bundleIdentifier else { return nil }
        guard let name = frontApp.localizedName else { return nil }

        let iconData = extractIconData(for: frontApp)

        return AppInfo(
            bundleID: bundleID,
            name: name,
            iconData: iconData,
            isActive: true,
            pid: UInt32(frontApp.processIdentifier)
        )
    }

    // MARK: - Private Methods

    /// 앱 아이콘 추출 (64x64 PNG)
    private func extractIconData(for app: NSRunningApplication) -> Data {
        guard let icon = app.icon else { return Data() }

        // 64x64 크기로 리사이즈
        let targetSize = NSSize(width: iconSize, height: iconSize)
        let resizedImage = NSImage(size: targetSize)

        resizedImage.lockFocus()
        icon.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: icon.size),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()

        // PNG로 변환
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return Data()
        }

        return pngData
    }
}
