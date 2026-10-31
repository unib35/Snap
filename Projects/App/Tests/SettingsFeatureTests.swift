import ComposableArchitecture
import Testing
@testable import App

@Suite("SettingsFeature 테스트")
struct SettingsFeatureTests {
    @Test("onAppear 시 저장된 설정을 로드하고 동기화 delegate를 보낸다")
    func onAppearLoadsStoredSettings() async {
        let loadedState = SettingsFeature.State(
            trackpadSensitivity: 1.3,
            scrollSensitivity: 1.7,
            laserSensitivity: 1.1,
            isNaturalScrolling: false,
            isTapToClick: false,
            isBatteryOptimizationEnabled: true,
            autoDetectLowPowerMode: false,
            reducedMotionUpdateRate: false
        )

        let store = await TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsClient.load = { loadedState }
            $0.settingsClient.isiCloudAvailable = { true }
        }

        await store.send(.onAppear) {
            $0 = loadedState
            $0.isiCloudAvailable = true
        }

        await store.receive(.delegate(.inputBehaviorChanged))
        await store.receive(.delegate(.powerSavingBehaviorChanged))
    }

    @Test("입력 설정 변경 시 저장과 input delegate를 함께 보낸다")
    func setTrackpadSensitivityEmitsSaveAndDelegate() async {
        let savedState = LockIsolated<SettingsFeature.State?>(nil)

        let store = await TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsClient.save = { savedState.setValue($0) }
        }

        await store.send(.setTrackpadSensitivity(1.6)) {
            $0.trackpadSensitivity = 1.6
        }

        await store.receive(.save)
        await store.receive(.delegate(.inputBehaviorChanged))

        #expect(savedState.value?.trackpadSensitivity == 1.6)
    }
}

extension SettingsFeatureTests {
    @Test("설정 재진입 후에도 현재 시스템 저전력 상태를 유지한다")
    func reloadPreservesSystemLowPowerMode() async {
        var initial = SettingsFeature.State()
        initial.isSystemLowPowerModeActive = true
        let store = await TestStore(initialState: initial) { SettingsFeature() } withDependencies: {
            $0.settingsClient.load = { SettingsFeature.State(trackpadSensitivity: 1.5) }
        }
        await store.send(.onAppear) {
            $0.trackpadSensitivity = 1.5
            $0.isiCloudAvailable = true
        }
        await store.receive(.delegate(.inputBehaviorChanged))
        await store.receive(.delegate(.powerSavingBehaviorChanged))
        #expect(await store.state.isInPowerSavingMode)
    }
}
