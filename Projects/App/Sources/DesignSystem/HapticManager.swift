import UIKit

// MARK: - Haptic Feedback Manager

/// 햅틱 피드백 매니저
@MainActor
public final class HapticManager {
    public static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        // 미리 준비하여 지연 최소화
        prepareAll()
    }

    // MARK: - Prepare

    /// 모든 햅틱 엔진 준비
    public func prepareAll() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionGenerator.prepare()
        notification.prepare()
    }

    // MARK: - Impact Feedback

    /// 가벼운 임팩트 (버튼 탭)
    public func lightImpact() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }

    /// 중간 임팩트 (토글, 스위치)
    public func mediumImpact() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// 강한 임팩트 (중요한 액션)
    public func heavyImpact() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }

    /// 부드러운 임팩트 (슬라이더)
    public func softImpact() {
        impactSoft.impactOccurred()
        impactSoft.prepare()
    }

    /// 단단한 임팩트 (딱딱한 터치)
    public func rigidImpact() {
        impactRigid.impactOccurred()
        impactRigid.prepare()
    }

    /// 커스텀 강도 임팩트
    public func impact(intensity: CGFloat, style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    // MARK: - Selection Feedback

    /// 선택 피드백 (목록 스크롤, 피커)
    public func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Notification Feedback

    /// 성공 알림
    public func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// 경고 알림
    public func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    /// 에러 알림
    public func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    // MARK: - Preset Patterns

    /// 버튼 탭 피드백
    public func buttonTap() {
        lightImpact()
    }

    /// 버튼 프레스 피드백 (길게 누름)
    public func buttonPress() {
        mediumImpact()
    }

    /// 토글 피드백
    public func toggle() {
        rigidImpact()
    }

    /// 슬라이더 틱 피드백
    public func sliderTick() {
        softImpact()
    }

    /// 연결 성공 피드백
    public func connectionSuccess() {
        success()
    }

    /// 연결 실패 피드백
    public func connectionFailed() {
        error()
    }

    /// 모드 전환 피드백
    public func modeSwitch() {
        mediumImpact()
    }

    /// 삭제 피드백
    public func delete() {
        heavyImpact()
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// 탭 시 햅틱 피드백 추가
    func hapticOnTap(_ style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    Task { @MainActor in
                        style.trigger()
                    }
                }
        )
    }
}

/// 햅틱 스타일
public enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case success
    case warning
    case error

    @MainActor
    func trigger() {
        switch self {
        case .light: HapticManager.shared.lightImpact()
        case .medium: HapticManager.shared.mediumImpact()
        case .heavy: HapticManager.shared.heavyImpact()
        case .soft: HapticManager.shared.softImpact()
        case .rigid: HapticManager.shared.rigidImpact()
        case .selection: HapticManager.shared.selection()
        case .success: HapticManager.shared.success()
        case .warning: HapticManager.shared.warning()
        case .error: HapticManager.shared.error()
        }
    }
}
