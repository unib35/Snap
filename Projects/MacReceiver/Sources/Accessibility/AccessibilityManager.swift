import Foundation
import ApplicationServices
import AppKit
import os

private let logger = Logger(subsystem: "com.snap.receiver", category: "AccessibilityManager")

/// 접근성 권한 관리자
@MainActor
public final class AccessibilityManager: ObservableObject {
    // MARK: - Singleton

    public static let shared = AccessibilityManager()

    // MARK: - Published Properties

    /// 접근성 권한 허용 여부
    @Published public private(set) var isAccessibilityEnabled: Bool = false

    // MARK: - Private Properties

    private var pollingTask: Task<Void, Never>?

    // MARK: - Initialization

    private init() {
        checkAccessibility()
    }

    // MARK: - Public Methods

    /// 접근성 권한 상태 확인
    public func checkAccessibility() {
        isAccessibilityEnabled = AXIsProcessTrusted()
        logger.info("Accessibility permission: \(self.isAccessibilityEnabled)")
    }

    /// 접근성 권한 요청 (시스템 다이얼로그 표시)
    public func requestAccessibility() {
        // kAXTrustedCheckOptionPrompt를 안전하게 사용
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        if !trusted {
            logger.info("Accessibility permission requested, starting polling...")
            startPollingForPermission()
        } else {
            isAccessibilityEnabled = true
        }
    }

    /// 시스템 환경설정 열기
    public func openSystemPreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
        startPollingForPermission()
    }

    // MARK: - Private Methods

    /// 권한 획득까지 폴링
    private func startPollingForPermission() {
        stopPolling()

        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                checkAccessibility()
                if isAccessibilityEnabled {
                    logger.info("Accessibility permission granted")
                    break
                }
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
