import CoreGraphics
import Shared
import Testing
@testable import MacReceiver

@Suite("Presentation commands")
@MainActor
struct PresentationControllerTests {
    @Test func startUsesShortcutOfFrontmostPresentationApp() {
        typealias Controller = PresentationController
        #expect(Controller.shortcut(for: .start, in: .keynote) == .init(35, [.maskCommand, .maskAlternate]))
        #expect(Controller.shortcut(for: .start, in: .powerPoint) == .init(36, [.maskCommand, .maskShift]))
        #expect(Controller.shortcut(for: .start, in: .browser) == .init(36, .maskCommand))
        #expect(Controller.shortcut(for: .start, in: .other) == nil)
        #expect(Controller.App(bundleID: "com.apple.iWork.Keynote") == .keynote)
        #expect(Controller.App(bundleID: "com.google.Chrome") == .browser)
        #expect(Controller.App(bundleID: nil) == .other)
    }

    @Test func sharedCommandsWorkInAnyApp() {
        for app in [PresentationController.App.keynote, .powerPoint, .browser, .other] {
            #expect(PresentationController.shortcut(for: .nextSlide, in: app) == .init(124))
            #expect(PresentationController.shortcut(for: .prevSlide, in: app) == .init(123))
            #expect(PresentationController.shortcut(for: .end, in: app) == .init(53))
            #expect(PresentationController.shortcut(for: .blankScreen, in: app) == .init(11))
        }
    }

    @Test func executePostsKeyDownAndUpWithModifiers() {
        var events: [CGEvent] = []
        let controller = PresentationController(
            postEvent: { events.append($0) },
            frontmostBundleID: { "com.apple.iWork.Keynote" }
        )
        #expect(controller.execute(command: .start))
        #expect(events.map(\.type) == [.keyDown, .keyUp])
        #expect(events.allSatisfy { $0.getIntegerValueField(.keyboardEventKeycode) == 35 })
        #expect(events.allSatisfy { $0.flags.contains([.maskCommand, .maskAlternate]) })
    }

    @Test func startIsSkippedInUnknownApp() {
        var events: [CGEvent] = []
        let controller = PresentationController(
            postEvent: { events.append($0) },
            frontmostBundleID: { "com.apple.finder" }
        )
        #expect(!controller.execute(command: .start))
        #expect(events.isEmpty)
    }
}
