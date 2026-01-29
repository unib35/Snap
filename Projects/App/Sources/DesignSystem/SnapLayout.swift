import SwiftUI

// MARK: - Layout Configuration

/// iPad 분할 화면 및 다양한 크기에 대응하는 레이아웃 설정
public enum SnapLayout {
    // MARK: - Size Class Detection

    /// 현재 레이아웃 모드
    public enum LayoutMode: Sendable {
        /// 컴팩트 너비 (iPhone 또는 iPad Slide Over/1/3 분할)
        case compact
        /// 중간 너비 (iPad 1/2 분할)
        case medium
        /// 전체 너비 (iPhone 가로 또는 iPad 2/3 이상)
        case regular

        /// 트랙패드 영역의 최대 너비
        var trackpadMaxWidth: CGFloat {
            switch self {
            case .compact: return .infinity
            case .medium: return 400
            case .regular: return 500
            }
        }

        /// 그리드 컬럼 수
        var gridColumns: Int {
            switch self {
            case .compact: return 4
            case .medium: return 4
            case .regular: return 6
            }
        }

        /// 사이드바 표시 여부
        var showSidebar: Bool {
            self == .regular
        }
    }

    /// 화면 너비에 따른 레이아웃 모드 결정
    public static func layoutMode(for width: CGFloat) -> LayoutMode {
        switch width {
        case ..<400:
            return .compact
        case 400..<600:
            return .medium
        default:
            return .regular
        }
    }
}

// MARK: - Layout Mode Environment Key

private struct LayoutModeKey: EnvironmentKey {
    static let defaultValue: SnapLayout.LayoutMode = .compact
}

public extension EnvironmentValues {
    /// 현재 레이아웃 모드
    var layoutMode: SnapLayout.LayoutMode {
        get { self[LayoutModeKey.self] }
        set { self[LayoutModeKey.self] = newValue }
    }
}

// MARK: - Adaptive Layout Modifier

/// 화면 크기에 따라 자동으로 레이아웃 모드를 설정하는 모디파이어
public struct AdaptiveLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            let mode = SnapLayout.layoutMode(for: geometry.size.width)

            content
                .environment(\.layoutMode, mode)
        }
    }
}

public extension View {
    /// 화면 크기에 따라 자동으로 레이아웃 모드를 설정
    func adaptiveLayout() -> some View {
        modifier(AdaptiveLayoutModifier())
    }
}

// MARK: - Compact Width View Modifier

/// 컴팩트 모드에서만 표시하는 모디파이어
public struct CompactOnlyModifier: ViewModifier {
    @Environment(\.layoutMode) private var layoutMode

    public func body(content: Content) -> some View {
        if layoutMode == .compact {
            content
        }
    }
}

/// 레귤러 모드에서만 표시하는 모디파이어
public struct RegularOnlyModifier: ViewModifier {
    @Environment(\.layoutMode) private var layoutMode

    public func body(content: Content) -> some View {
        if layoutMode == .regular {
            content
        }
    }
}

public extension View {
    /// 컴팩트 모드에서만 표시
    func compactOnly() -> some View {
        modifier(CompactOnlyModifier())
    }

    /// 레귤러 모드에서만 표시
    func regularOnly() -> some View {
        modifier(RegularOnlyModifier())
    }
}

// MARK: - Adaptive Grid

/// 레이아웃 모드에 따라 컬럼 수가 변하는 그리드
public struct AdaptiveGrid<Content: View>: View {
    @Environment(\.layoutMode) private var layoutMode

    let spacing: CGFloat
    let content: Content

    public init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: layoutMode.gridColumns
        )

        LazyVGrid(columns: columns, spacing: spacing) {
            content
        }
    }
}

// MARK: - Adaptive Stack

/// 레이아웃 모드에 따라 HStack/VStack 전환
public struct AdaptiveStack<Content: View>: View {
    @Environment(\.layoutMode) private var layoutMode

    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content

    public init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if layoutMode == .regular {
            HStack(alignment: verticalAlignment, spacing: spacing) {
                content
            }
        } else {
            VStack(alignment: horizontalAlignment, spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - Trackpad Area Constraint

/// 트랙패드 영역의 최대 크기를 레이아웃 모드에 맞게 제한
public struct TrackpadAreaConstraint: ViewModifier {
    @Environment(\.layoutMode) private var layoutMode

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: layoutMode.trackpadMaxWidth)
    }
}

public extension View {
    /// 트랙패드 영역의 최대 크기를 레이아웃 모드에 맞게 제한
    func trackpadAreaConstraint() -> some View {
        modifier(TrackpadAreaConstraint())
    }
}

// MARK: - iPad Optimized Container

/// iPad에서 분할 화면 시 중앙 정렬 및 최대 너비 제한
public struct iPadOptimizedContainer<Content: View>: View {
    @Environment(\.layoutMode) private var layoutMode

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        if layoutMode == .regular {
            HStack {
                Spacer(minLength: 0)
                content
                    .frame(maxWidth: 600)
                Spacer(minLength: 0)
            }
        } else {
            content
        }
    }
}
