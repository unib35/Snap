import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Semantic colors shared by the sender and receiver. System colors adapt to
/// appearance and increased contrast; accent is inherited from the view tree.
public enum SnapPalette {
    public static let accent = Color.accentColor
    public static let defaultAccent = Color.blue
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textTertiary = Color.secondary
    public static let textDisabled = Color.secondary.opacity(0.5)

    #if os(iOS)
    public static let background = Color(uiColor: .systemGroupedBackground)
    public static let backgroundElevated = Color(uiColor: .secondarySystemGroupedBackground)
    public static let backgroundTertiary = Color(uiColor: .tertiarySystemFill)
    public static let backgroundHighlight = Color(uiColor: .secondarySystemFill)
    public static let border = Color(uiColor: .separator).opacity(0.5)
    #else
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let backgroundElevated = Color(nsColor: .controlBackgroundColor)
    public static let backgroundTertiary = Color(nsColor: .quaternaryLabelColor).opacity(0.12)
    public static let backgroundHighlight = Color(nsColor: .quaternaryLabelColor).opacity(0.2)
    public static let border = Color(nsColor: .separatorColor)
    #endif

    public static let borderHighlight = border
    public static let divider = border
    public static let separator = border
    public static let systemBackground = background
    public static let secondarySystemBackground = backgroundElevated
    public static let tertiarySystemBackground = backgroundTertiary
    public static let tertiarySystemFill = backgroundHighlight
    public static let label = textPrimary
    public static let secondaryLabel = textSecondary
    public static let tertiaryLabel = textTertiary

    public static let success = Color.green
    public static let warning = Color.orange
    public static let destructive = Color.red
    public static let recording = Color.red
    public static let laserPointer = Color.red
    public static let statusConnected = success
    public static let statusConnecting = accent
    public static let statusDiscovering = accent
    public static let statusDisconnected = textSecondary

    /// Presentation controls intentionally use a dark stage, independent of
    /// the surrounding navigation. QR codes also require a fixed white canvas.
    public static let focusBackground = Color.black
    public static let qrBackground = Color.white
}
