import ComposableArchitecture
import Foundation
import Shared
import Testing
@testable import App

/// 발표 화면의 버튼이 Mac에 발표 명령을 보내는지 확인한다.
@MainActor
@Suite("발표 명령 전송 테스트")
struct PresenterFeatureTests {
    @Test("슬라이드 이동과 화면 가리기가 발표 명령으로 전송됨")
    func sendsPresentationCommands() async throws {
        let sent = LockIsolated<[Presentation.Command]>([])
        let defaults = try #require(UserDefaults(suiteName: "snap.tests.\(UUID().uuidString)"))
        let store = TestStore(initialState: PresenterFeature.State()) {
            PresenterFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.connectionClient.sendPresentation = { command in sent.withValue { $0.append(command) } }
        }
        store.exhaustivity = .off

        await store.send(.nextSlide)
        await store.receive(\.triggerAlert)
        await store.send(.previousSlide)
        await store.receive(\.triggerAlert)
        await store.send(.toggleScreenBlank) {
            $0.isScreenBlank = true
        }
        await store.finish()

        #expect(sent.value == [.nextSlide, .prevSlide, .blankScreen])
    }

    @Test("발표 시작과 종료가 Mac에 전달되고 타이머가 함께 움직임")
    func startAndEndPresentation() async throws {
        let sent = LockIsolated<[Presentation.Command]>([])
        let defaults = try #require(UserDefaults(suiteName: "snap.tests.\(UUID().uuidString)"))
        let clock = TestClock()
        let store = TestStore(initialState: PresenterFeature.State()) {
            PresenterFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.continuousClock = clock
            $0.connectionClient.sendPresentation = { command in sent.withValue { $0.append(command) } }
        }

        await store.send(.startPresentation) {
            $0.isPresenting = true
        }
        await store.receive(\.startTimer) {
            $0.isTimerRunning = true
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.timerTick) {
            $0.elapsedSeconds = 1
        }
        await store.send(.endPresentation) {
            $0.isPresenting = false
        }
        await store.receive(\.stopTimer) {
            $0.isTimerRunning = false
        }

        #expect(sent.value == [.start, .end])
    }
}
