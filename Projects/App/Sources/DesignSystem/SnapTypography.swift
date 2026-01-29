import SwiftUI

// MARK: - SnapTypography

/// Snap 앱의 타이포그래피 시스템.
///
/// `SnapTypography`는 iOS Dynamic Type을 완벽히 지원하는 폰트 스타일 세트를 제공합니다.
/// 사용자의 시스템 글꼴 크기 설정에 따라 자동으로 스케일됩니다.
///
/// ## 폰트 카테고리
/// - **Display**: 대형 제목 (largeTitle, title, title2)
/// - **Headlines**: 섹션 제목 (title3, headline, subheadline)
/// - **Body**: 본문 텍스트 (body, callout, footnote)
/// - **Labels**: UI 레이블 (subheadline, caption, caption2)
/// - **Monospace**: 숫자, 코드 표시용
///
/// ## 사용 예제
/// ```swift
/// Text("Welcome")
///     .font(SnapTypography.displayLarge)
///
/// Text("Section Title")
///     .font(SnapTypography.headlineMedium)
///
/// Text("Body text here")
///     .font(SnapTypography.bodyMedium)
/// ```
///
/// ## Dynamic Type 지원
/// 모든 폰트는 `Font.TextStyle`을 기반으로 하여 자동 스케일링됩니다.
/// 레이아웃이 민감한 UI에서는 `.limitAccessibilitySize()` 또는
/// `.accessibleControl()` 수정자를 사용하세요.
///
/// - SeeAlso: ``SnapColors``, ``SnapSpacing``, ``ScaledIconSize``
public enum SnapTypography {
    // MARK: - Display (대형 제목)

    /// 대형 제목 (largeTitle 기반, Bold, Rounded)
    public static let displayLarge = Font.system(.largeTitle, design: .rounded, weight: .bold)

    /// 중형 제목 (title 기반, Bold, Rounded)
    public static let displayMedium = Font.system(.title, design: .rounded, weight: .bold)

    /// 소형 제목 (title2 기반, Semibold, Rounded)
    public static let displaySmall = Font.system(.title2, design: .rounded, weight: .semibold)

    // MARK: - Headlines

    /// 헤드라인 대 (title3 기반, Semibold, Rounded)
    public static let headlineLarge = Font.system(.title3, design: .rounded, weight: .semibold)

    /// 헤드라인 중 (headline 기반, Semibold, Rounded)
    public static let headlineMedium = Font.system(.headline, design: .rounded, weight: .semibold)

    /// 헤드라인 소 (subheadline 기반, Semibold, Rounded)
    public static let headlineSmall = Font.system(.subheadline, design: .rounded, weight: .semibold)

    // MARK: - Body

    /// 본문 대 (body 기반, Regular)
    public static let bodyLarge = Font.system(.body, design: .default, weight: .regular)

    /// 본문 중 (callout 기반, Regular)
    public static let bodyMedium = Font.system(.callout, design: .default, weight: .regular)

    /// 본문 소 (footnote 기반, Regular)
    public static let bodySmall = Font.system(.footnote, design: .default, weight: .regular)

    // MARK: - Labels

    /// 레이블 대 (subheadline 기반, Medium)
    public static let labelLarge = Font.system(.subheadline, design: .default, weight: .medium)

    /// 레이블 중 (caption 기반, Medium)
    public static let labelMedium = Font.system(.caption, design: .default, weight: .medium)

    /// 레이블 소 (caption2 기반, Medium)
    public static let labelSmall = Font.system(.caption2, design: .default, weight: .medium)

    // MARK: - Caption

    /// 캡션 (caption2 기반, Regular)
    public static let caption = Font.system(.caption2, design: .default, weight: .regular)

    // MARK: - Monospace (숫자, 코드)

    /// 모노스페이스 대 (body 기반, Monospaced)
    public static let monoLarge = Font.system(.body, design: .monospaced, weight: .medium)

    /// 모노스페이스 중 (callout 기반, Monospaced)
    public static let monoMedium = Font.system(.callout, design: .monospaced, weight: .medium)

    /// 모노스페이스 소 (footnote 기반, Monospaced)
    public static let monoSmall = Font.system(.footnote, design: .monospaced, weight: .medium)
}

// MARK: - Dynamic Type Size Limits

/// Dynamic Type 크기 제한을 위한 View Modifier
public struct DynamicTypeSizeModifier: ViewModifier {
    let minSize: DynamicTypeSize
    let maxSize: DynamicTypeSize

    public func body(content: Content) -> some View {
        content
            .dynamicTypeSize(minSize...maxSize)
    }
}

public extension View {
    /// Dynamic Type 크기를 제한합니다.
    /// - Parameters:
    ///   - min: 최소 크기 (기본값: .xSmall)
    ///   - max: 최대 크기 (기본값: .accessibility3)
    func limitDynamicTypeSize(
        min: DynamicTypeSize = .xSmall,
        max: DynamicTypeSize = .accessibility3
    ) -> some View {
        modifier(DynamicTypeSizeModifier(minSize: min, maxSize: max))
    }

    /// 접근성 크기를 제한하면서 일반 크기는 허용합니다.
    /// 컨트롤이나 버튼 등 레이아웃이 민감한 UI에 사용합니다.
    func limitAccessibilitySize() -> some View {
        modifier(DynamicTypeSizeModifier(minSize: .xSmall, maxSize: .xxxLarge))
    }
}

// MARK: - Scaled Spacing

/// Dynamic Type에 따라 스케일되는 간격을 위한 Property Wrapper
/// View 내에서 사용해야 합니다.
///
/// 예시:
/// ```swift
/// struct MyView: View {
///     @ScaledMetric(relativeTo: .body) private var spacing: CGFloat = 8
///
///     var body: some View {
///         VStack(spacing: spacing) { ... }
///     }
/// }
/// ```
public enum ScaledSpacing {
    /// 작은 간격 (4pt 기준)
    public static let small: CGFloat = 4

    /// 중간 간격 (8pt 기준)
    public static let medium: CGFloat = 8

    /// 큰 간격 (16pt 기준)
    public static let large: CGFloat = 16

    /// 아주 큰 간격 (24pt 기준)
    public static let extraLarge: CGFloat = 24
}

// MARK: - Scaled Icon Sizes

/// Dynamic Type에 따라 스케일되는 아이콘 크기
/// View 내에서 @ScaledMetric과 함께 사용합니다.
///
/// 예시:
/// ```swift
/// struct MyView: View {
///     @ScaledMetric(relativeTo: .body) private var iconSize = ScaledIconSize.medium
///
///     var body: some View {
///         Image(systemName: "star.fill")
///             .font(.system(size: iconSize))
///     }
/// }
/// ```
public enum ScaledIconSize {
    /// 작은 아이콘 (16pt 기준)
    public static let small: CGFloat = 16

    /// 중간 아이콘 (20pt 기준)
    public static let medium: CGFloat = 20

    /// 큰 아이콘 (24pt 기준)
    public static let large: CGFloat = 24

    /// 특대 아이콘 (32pt 기준)
    public static let extraLarge: CGFloat = 32

    /// 컨트롤 버튼 아이콘 (44pt 기준)
    public static let control: CGFloat = 44
}

// MARK: - Accessibility-Friendly Text Styles

public extension View {
    /// 텍스트에 Dynamic Type을 적용하면서 최대 크기를 제한합니다.
    /// 일반 텍스트에 사용합니다.
    func accessibleText() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// 컨트롤(버튼, 레이블)에 Dynamic Type을 적용하면서 최대 크기를 제한합니다.
    /// 레이아웃이 민감한 UI에 사용합니다.
    func accessibleControl() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
