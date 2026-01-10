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

    // MARK: - Settings

    /// 햅틱 활성화 여부 (설정에서 "끔"이 아닌 경우)
    public var isEnabled: Bool {
        hapticIntensity != 0
    }

    /// 현재 햅틱 강도 설정 (0: 끔, 1: 약하게, 2: 보통, 3: 강하게)
    private var hapticIntensity: Int {
        let value = UserDefaults.standard.integer(forKey: "hapticIntensity")
        // UserDefaults에 값이 없으면 0을 반환하므로, 기본값 2(보통)로 설정
        // 단, 사용자가 명시적으로 0(끔)을 선택한 경우는 0 유지
        return UserDefaults.standard.object(forKey: "hapticIntensity") == nil ? 2 : value
    }

    /// 설정된 강도에 따른 intensity 배율
    private var intensityMultiplier: CGFloat {
        switch hapticIntensity {
        case 1: return 0.5   // 약하게
        case 2: return 1.0   // 보통
        case 3: return 1.0   // 강하게 (더 강한 스타일 사용)
        default: return 1.0
        }
    }

    /// 강하게 설정 시 더 강한 스타일 사용 여부
    private var useStrongerStyle: Bool {
        hapticIntensity == 3
    }

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
        guard isEnabled else { return }
        let generator = useStrongerStyle ? impactMedium : impactLight
        generator.impactOccurred(intensity: intensityMultiplier)
        generator.prepare()
    }

    /// 중간 임팩트 (토글, 스위치)
    public func mediumImpact() {
        guard isEnabled else { return }
        let generator = useStrongerStyle ? impactHeavy : impactMedium
        generator.impactOccurred(intensity: intensityMultiplier)
        generator.prepare()
    }

    /// 강한 임팩트 (중요한 액션)
    public func heavyImpact() {
        guard isEnabled else { return }
        let generator = useStrongerStyle ? impactRigid : impactHeavy
        generator.impactOccurred(intensity: intensityMultiplier)
        generator.prepare()
    }

    /// 부드러운 임팩트 (슬라이더)
    public func softImpact() {
        guard isEnabled else { return }
        let generator = useStrongerStyle ? impactMedium : impactSoft
        generator.impactOccurred(intensity: intensityMultiplier)
        generator.prepare()
    }

    /// 단단한 임팩트 (딱딱한 터치)
    public func rigidImpact() {
        guard isEnabled else { return }
        impactRigid.impactOccurred(intensity: intensityMultiplier)
        impactRigid.prepare()
    }

    /// 커스텀 강도 임팩트
    public func impact(intensity: CGFloat, style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity * intensityMultiplier)
    }

    // MARK: - Selection Feedback

    /// 선택 피드백 (목록 스크롤, 피커)
    public func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Notification Feedback

    /// 성공 알림
    public func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// 경고 알림
    public func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    /// 에러 알림
    public func error() {
        guard isEnabled else { return }
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
