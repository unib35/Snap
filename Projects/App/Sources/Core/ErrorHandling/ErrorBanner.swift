import SwiftUI

/// 에러 배너 뷰
///
/// 화면 하단에 표시되는 에러 알림 배너입니다.
/// 닫기 버튼과 선택적 재시도 버튼을 제공합니다.
public struct ErrorBanner: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    public init(
        error: AppError,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = error.canRetry ? onRetry : nil
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(error.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(error.userMessage)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            if let onRetry {
                HStack(spacing: 12) {
                    Spacer()

                    if error.shouldOpenSettings {
                        Button("설정 열기") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.white)
                    }

                    Button("다시 시도") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.white)
                }
            } else if error.shouldOpenSettings {
                HStack {
                    Spacer()
                    Button("설정 열기") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.white)
                }
            }
        }
        .padding()
        .background(.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

/// View modifier for displaying error banners
public struct ErrorBannerModifier: ViewModifier {
    let error: AppError?
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let error {
                    ErrorBanner(
                        error: error,
                        onDismiss: onDismiss,
                        onRetry: onRetry
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: error != nil)
    }
}

public extension View {
    /// 에러 배너를 표시하는 modifier
    func errorBanner(
        _ error: AppError?,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorBannerModifier(error: error, onDismiss: onDismiss, onRetry: onRetry))
    }
}
