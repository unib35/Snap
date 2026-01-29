import SwiftUI

// MARK: - SnapColors

/// Snap 앱의 색상 시스템.
///
/// `SnapColors`는 OLED 디스플레이에 최적화된 딥 다크 모드 컬러 팔레트를 제공합니다.
/// 모든 색상은 정적 프로퍼티로 제공되어 일관된 시각적 경험을 보장합니다.
///
/// ## 색상 카테고리
/// - **배경색**: 계층 구조를 표현하는 4단계 배경색
/// - **네온 액센트**: 강렬한 시각적 강조를 위한 네온 색상
/// - **텍스트**: 가독성을 고려한 4단계 텍스트 색상
/// - **시스템 별칭**: SwiftUI 시스템 색상의 다크 모드 대체
/// - **상태 색상**: 연결 상태, 녹음 상태 등 시맨틱 색상
///
/// ## 사용 예제
/// ```swift
/// Text("Hello")
///     .foregroundStyle(SnapColors.textPrimary)
///     .background(SnapColors.backgroundElevated)
///
/// Circle()
///     .fill(SnapColors.statusConnected)
/// ```
///
/// ## OLED 최적화
/// 배경색은 순수 검정(#000000)부터 시작하여 OLED 디스플레이에서
/// 완벽한 블랙을 표현하고 배터리 효율을 높입니다.
///
/// - Note: 모든 색상은 다크 모드 전용으로 설계되었습니다.
/// - SeeAlso: ``SnapTypography``, ``SnapSpacing``
public enum SnapColors {
    // MARK: - Background Colors (Deep Dark)

    /// 순수 검정 배경 (OLED 최적화)
    public static let background = Color.black

    /// 약간 밝은 배경 (카드, 시트)
    public static let backgroundElevated = Color(white: 0.08)

    /// 더 밝은 배경 (입력 필드, 선택된 항목)
    public static let backgroundTertiary = Color(white: 0.12)

    /// 호버/프레스 상태 배경
    public static let backgroundHighlight = Color(white: 0.16)

    // MARK: - Neon Accent Colors

    /// 라임 그린 (Primary Accent)
    public static let neonLime = Color(red: 0.75, green: 1.0, blue: 0.0)

    /// 사이버 블루 (Secondary Accent)
    public static let cyberBlue = Color(red: 0.0, green: 0.9, blue: 1.0)

    /// 네온 핑크 (Tertiary Accent)
    public static let neonPink = Color(red: 1.0, green: 0.2, blue: 0.6)

    /// 네온 오렌지 (Warning)
    public static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    /// 네온 레드 (Error/Destructive)
    public static let neonRed = Color(red: 1.0, green: 0.25, blue: 0.25)

    // MARK: - Text Colors

    /// 기본 텍스트 (흰색)
    public static let textPrimary = Color.white

    /// 보조 텍스트 (밝은 회색)
    public static let textSecondary = Color(white: 0.7)

    /// 비활성 텍스트 (어두운 회색)
    public static let textTertiary = Color(white: 0.45)

    /// 비활성화된 텍스트
    public static let textDisabled = Color(white: 0.3)

    // MARK: - System Color Aliases (시스템 색상 대체용)

    /// systemBackground 대체
    public static let systemBackground = background

    /// secondarySystemBackground 대체
    public static let secondarySystemBackground = backgroundElevated

    /// tertiarySystemBackground 대체
    public static let tertiarySystemBackground = backgroundTertiary

    /// tertiarySystemFill 대체
    public static let tertiarySystemFill = backgroundHighlight

    /// label 대체
    public static let label = textPrimary

    /// secondaryLabel 대체
    public static let secondaryLabel = textSecondary

    /// tertiaryLabel 대체
    public static let tertiaryLabel = textTertiary

    /// separator 대체
    public static let separator = Color(white: 0.2)

    // MARK: - Border & Divider

    /// 기본 테두리
    public static let border = Color(white: 0.2)

    /// 강조 테두리
    public static let borderHighlight = Color(white: 0.3)

    /// 구분선
    public static let divider = Color(white: 0.15)

    // MARK: - Connection Status Colors

    /// 연결됨 (Neon Lime)
    public static let statusConnected = neonLime

    /// 연결 중 (Neon Orange)
    public static let statusConnecting = neonOrange

    /// 검색 중 (Cyber Blue)
    public static let statusDiscovering = cyberBlue

    /// 연결 끊김 (Neon Red)
    public static let statusDisconnected = neonRed

    // MARK: - Semantic Colors (상태별 고정 색상)

    /// 녹음 중 상태 (빨강)
    public static let recording = Color.red

    /// 파괴적 액션 (삭제 등)
    public static let destructive = Color.red

    /// 경고 상태
    public static let warning = Color.orange

    /// 성공 상태
    public static let success = Color.green

    /// 레이저 포인터 (빨강 고정 - 실제 레이저 포인터 색상)
    public static let laserPointer = Color.red
}
