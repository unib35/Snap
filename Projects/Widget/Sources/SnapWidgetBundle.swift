import SwiftUI
import WidgetKit

@main
struct SnapWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickConnectWidget()
        MacroWidget()
    }
}
