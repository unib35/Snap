import ComposableArchitecture
import Shared
import SwiftUI
import Testing
@testable import App

@Suite("AppFeature 테스트")
struct AppFeatureTests {
    @Test("앱 시작 시 discovery, network monitoring, onboarding 확인을 시작")
    func onAppearBootstrapsAppServices() async {
        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.onboardingClient.hasCompletedOnboarding = { true }
            $0.connectionClient.startDiscovery = { .finished }
            $0.networkMonitorClient.startMonitoring = { .finished }
            $0.batteryClient.observeLowPowerMode = { .finished }
        }

        await store.send(.onAppear)

        await store.receive({
            if case .checkOnboardingStatus = $0 { return true }
            return false
        }, assert: {
            $0.isOnboarded = true
        })

        await store.receive({
            if case .connection(.startDiscovery) = $0 { return true }
            return false
        }, assert: {
            $0.connection.status = .discovering
            $0.connection.discoveredDevices.removeAll()
        })

        await store.receive {
            if case .connection(.startNetworkMonitoring) = $0 { return true }
            return false
        }
    }

    @Test("Mac에서 받은 볼륨 상태를 미디어 화면에 전달")
    func volumeStateIsRoutedToMedia() async {
        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        let volumeState = VolumeState(volume: 0.6, isMuted: false)

        await store.send(.connection(.volumeStateReceived(volumeState)))
        await store.receive(\.media.volumeStateReceived) {
            $0.media.volume = 0.6
            $0.media.hasReceivedVolume = true
        }
    }

    @Test("active scene 전환 시 재연결과 네트워크 감시를 재시작")
    func scenePhaseActiveRestartsConnectionHooks() async {
        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.networkMonitorClient.startMonitoring = { .finished }
        }

        await store.send(.scenePhaseChanged(.active))
        await store.receive {
            if case .connection(.startNetworkMonitoring) = $0 { return true }
            return false
        }
        await store.receive {
            if case .connection(.appDidBecomeActive) = $0 { return true }
            return false
        }
    }

    @Test("background scene 전환 시 네트워크 감시를 중지")
    func scenePhaseBackgroundStopsNetworkMonitoring() async {
        let stopMonitoringCalled = LockIsolated(false)

        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.networkMonitorClient.stopMonitoring = {
                stopMonitoringCalled.setValue(true)
            }
        }

        await store.send(.scenePhaseChanged(.background))
        await store.receive {
            if case .connection(.appWillResignActive) = $0 { return true }
            return false
        }
        await store.receive {
            if case .connection(.stopNetworkMonitoring) = $0 { return true }
            return false
        }

        #expect(stopMonitoringCalled.value)
    }

    @Test("입력 설정 delegate 수신 시 trackpad와 laser live state를 동기화")
    func inputSettingsDelegateSyncsLiveInputState() async {
        var state = AppFeature.State()
        state.settings = SettingsFeature.State(
            trackpadSensitivity: 1.4,
            scrollSensitivity: 1.8,
            laserSensitivity: 1.2,
            isNaturalScrolling: false,
            isTapToClick: false
        )

        let store = await TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.settings(.delegate(.inputBehaviorChanged)))

        await store.receive({
            if case .trackpad(.updateSettings(
                sensitivity: 1.4,
                scrollSensitivity: 1.8,
                isNaturalScrolling: false,
                isTapToClick: false
            )) = $0 { return true }
            return false
        }, assert: {
            $0.trackpad.sensitivity = 1.4
            $0.trackpad.scrollSensitivity = 1.8
            $0.trackpad.isNaturalScrolling = false
            $0.trackpad.isTapToClick = false
        })

        await store.receive({
            if case .trackpad(.laserPointer(.setSensitivity(let value))) = $0 {
                return value == 18.0
            }
            return false
        }, assert: {
            $0.trackpad.laserPointer.sensitivity = 18.0
        })
    }

    @Test("배터리 절약 delegate 수신 시 trackpad 절약 모드를 동기화")
    func powerSavingDelegateSyncsTrackpadPowerState() async {
        var state = AppFeature.State()
        state.settings = SettingsFeature.State(
            isBatteryOptimizationEnabled: true,
            autoDetectLowPowerMode: false,
            reducedMotionUpdateRate: false
        )

        let store = await TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.settings(.delegate(.powerSavingBehaviorChanged)))

        await store.receive({
            if case .trackpad(.updatePowerSavingMode(
                isInPowerSavingMode: true,
                reducedMotionUpdateRate: false
            )) = $0 { return true }
            return false
        }, assert: {
            $0.trackpad.isInPowerSavingMode = true
            $0.trackpad.reducedMotionUpdateRate = false
        })

        await store.receive({
            if case .trackpad(.laserPointer(.updatePowerSavingMode(false))) = $0 { return true }
            return false
        })
    }
}
