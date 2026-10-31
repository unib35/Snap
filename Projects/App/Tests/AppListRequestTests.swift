import ComposableArchitecture
import Shared
import Testing
@testable import App

@Suite("앱 목록 요청 테스트")
struct AppListRequestTests {
    @Test("응답이 없으면 시간 초과 후 로딩을 끝내고 오류 표시")
    func requestTimesOut() async {
        let clock = TestClock()
        let store = await TestStore(initialState: ProductivityFeature.State()) {
            ProductivityFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.connectionClient.requestAppList = {}
        }

        await store.send(.requestAppListTapped) {
            $0.isLoadingApps = true
        }
        await clock.advance(by: ProductivityFeature.appListTimeout)
        await store.receive(.appListTimedOut) {
            $0.isLoadingApps = false
            $0.appListError = .timeout
        }
    }

    @Test("시간 안에 응답이 오면 시간 초과하지 않음")
    func responseCancelsTimeout() async {
        let clock = TestClock()
        let apps = [AppInfo(bundleID: "com.apple.Safari", name: "Safari", pid: 1)]
        let store = await TestStore(initialState: ProductivityFeature.State()) {
            ProductivityFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.connectionClient.requestAppList = {}
        }

        await store.send(.requestAppListTapped) {
            $0.isLoadingApps = true
        }
        await store.send(.appListReceived(apps)) {
            $0.isLoadingApps = false
            $0.runningApps = apps
        }
        await clock.advance(by: ProductivityFeature.appListTimeout)
    }

    @Test("다시 요청하면 이전 오류를 지움")
    func retryClearsError() async {
        let clock = TestClock()
        var state = ProductivityFeature.State()
        state.appListError = .timeout

        let store = await TestStore(initialState: state) {
            ProductivityFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.connectionClient.requestAppList = {}
        }

        await store.send(.requestAppListTapped) {
            $0.isLoadingApps = true
            $0.appListError = nil
        }
        await clock.advance(by: ProductivityFeature.appListTimeout)
        await store.receive(.appListTimedOut) {
            $0.isLoadingApps = false
            $0.appListError = .timeout
        }
    }
}
