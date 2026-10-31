import SwiftUI
import WidgetKit

@main
struct SnapWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        QuickConnectWidget()
        MacroWidget()
        MediaControlWidget()

        // Lock Screen / Dynamic Island
        SnapLiveActivity()

        // Control Center (iOS 18+)
        if #available(iOS 18.0, *) {
            SnapControlWidget()
            TrackpadControlWidget()
            KeyboardControlWidget()
            MediaControlControlWidget()
        }
    }
}
