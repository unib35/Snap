import SwiftUI
import WidgetKit

@main
struct SnapWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        QuickConnectWidget()
        MacroWidget()
        MediaControlWidget()
    }
}

// Note: Control Center widgets (SnapControlWidget, TrackpadControlWidget,
// KeyboardControlWidget, MediaControlControlWidget) are defined in
// SnapControlWidget.swift with @available(iOS 18.0, *).
// They are automatically discovered by the system on iOS 18+.
