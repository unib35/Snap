import ComposableArchitecture
import Foundation
import Testing
@testable import App

/// 기능 화면 안의 옵션이 앱을 다시 열어도 유지되는지 확인한다.
@MainActor
@Suite("기능 옵션 저장 테스트")
struct FeatureOptionsPersistenceTests {
    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "snap.tests.\(UUID().uuidString)"))
    }

    @Test("발표 옵션을 바꾸면 저장되고 새 상태에서 불러옴")
    func presenterOptionsPersist() async throws {
        let defaults = try makeDefaults()
        let store = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            TestStore(initialState: PresenterFeature.State()) {
                PresenterFeature()
            }
        }

        await store.send(.setTimerMode(.countDown)) {
            $0.$timerMode.withLock { $0 = .countDown }
        }
        await store.send(.setTargetMinutes(12)) {
            $0.$targetMinutes.withLock { $0 = 12 }
        }
        await store.send(.setAlertType(.both)) {
            $0.$alertType.withLock { $0 = .both }
        }
        await store.send(.toggleFiveMinuteAlert) {
            $0.$fiveMinuteAlert.withLock { $0 = false }
        }
        await store.send(.toggleAutoSlide) {
            $0.$isAutoSlideEnabled.withLock { $0 = true }
        }
        await store.send(.setAutoSlideInterval(45)) {
            $0.$autoSlideInterval.withLock { $0 = 45 }
        }

        let restored = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            PresenterFeature.State()
        }
        #expect(restored.timerMode == .countDown)
        #expect(restored.targetMinutes == 12)
        #expect(restored.alertType == .both)
        #expect(restored.fiveMinuteAlert == false)
        #expect(restored.isAutoSlideEnabled == true)
        #expect(restored.autoSlideInterval == 45)
    }

    @Test("레이저 작동 방식이 저장됨")
    func laserActivationModePersists() async throws {
        let defaults = try makeDefaults()
        let store = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            TestStore(initialState: LaserPointerFeature.State()) {
                LaserPointerFeature()
            }
        }

        await store.send(.setActivationMode(.toggle)) {
            $0.$activationMode.withLock { $0 = .toggle }
        }

        let restored = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            LaserPointerFeature.State()
        }
        #expect(restored.activationMode == .toggle)
    }

    @Test("숏폼 플랫폼과 자동 넘김 간격이 저장됨")
    func shortsOptionsPersist() async throws {
        let defaults = try makeDefaults()
        let store = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            TestStore(initialState: ShortsRemoteFeature.State()) {
                ShortsRemoteFeature()
            }
        }

        await store.send(.platformSelected(.tiktok)) {
            $0.$selectedPlatform.withLock { $0 = .tiktok }
        }
        await store.send(.setAutoScrollInterval(20)) {
            $0.$autoScrollInterval.withLock { $0 = 20 }
        }

        let restored = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            ShortsRemoteFeature.State()
        }
        #expect(restored.selectedPlatform == .tiktok)
        #expect(restored.autoScrollInterval == 20)
    }

    @Test("레이저 화면에서 바꾼 감도를 설정 배율로 전달")
    func laserSliderReportsSensitivity() async throws {
        let defaults = try makeDefaults()
        let store = TestStore(initialState: LaserPointerFeature.State()) {
            LaserPointerFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.motionClient.setSensitivity = { _ in }
        }

        await store.send(.sensitivitySliderChanged(30)) {
            $0.sensitivity = 30
        }
        await store.receive(\.delegate.sensitivityChanged)
        #expect(LaserPointerFeature.settingsMultiplier(for: 30) == 2.0)
        #expect(LaserPointerFeature.settingsMultiplier(for: 7.5) == 0.5)
    }
}
