import SwiftUI

// MARK: - Snap Spacing System

/// 간격 시스템 (8pt 기반)
public enum SnapSpacing {
    /// 2pt
    public static let xxs: CGFloat = 2

    /// 4pt
    public static let xs: CGFloat = 4

    /// 8pt
    public static let sm: CGFloat = 8

    /// 12pt
    public static let md: CGFloat = 12

    /// 16pt
    public static let lg: CGFloat = 16

    /// 20pt
    public static let xl: CGFloat = 20

    /// 24pt
    public static let xxl: CGFloat = 24

    /// 32pt
    public static let xxxl: CGFloat = 32

    /// 48pt
    public static let huge: CGFloat = 48
}

// MARK: - Corner Radius

/// 모서리 반경
public enum SnapCornerRadius {
    /// 4pt (작은 요소)
    public static let xs: CGFloat = 4

    /// 8pt (버튼, 입력)
    public static let sm: CGFloat = 8

    /// 12pt (카드)
    public static let md: CGFloat = 12

    /// 16pt (큰 카드)
    public static let lg: CGFloat = 16

    /// 20pt (시트)
    public static let xl: CGFloat = 20

    /// 24pt (모달)
    public static let xxl: CGFloat = 24

    /// 완전 원형
    public static let full: CGFloat = 9999
}

// MARK: - Shadow

/// 그림자 스타일
public enum SnapShadow {
    /// 작은 그림자
    public static let sm = Shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

    /// 중간 그림자
    public static let md = Shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)

    /// 큰 그림자
    public static let lg = Shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)

    /// 네온 글로우 (라임)
    public static let glowLime = Shadow(color: SnapColors.neonLime.opacity(0.4), radius: 12, x: 0, y: 0)

    /// 네온 글로우 (블루)
    public static let glowBlue = Shadow(color: SnapColors.cyberBlue.opacity(0.4), radius: 12, x: 0, y: 0)
}

/// 그림자 정의
public struct Shadow: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

extension View {
    /// 그림자 적용
    func snapShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
