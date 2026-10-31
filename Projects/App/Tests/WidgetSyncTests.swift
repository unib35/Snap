import ComposableArchitecture
import Foundation
import Shared
import Testing
@testable import App

@Suite("위젯 동기화 테스트")
struct WidgetSyncTests {
    private let device = Device(id: "mac-1", name: "MacBook Pro", host: "192.168.0.2", port: 9000)

    @Test("연결 상태가 바뀌면 위젯에 새 연결 상태를 전달")
    func connectionChangeUpdatesWidget() async {
        let updates = LockIsolated<[WidgetConnectionState]>([])
        var state = AppFeature.State()
        state.connection.status = .connected(device)
        state.connection.connectedDevice = device

        let store = await TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.connectionClient.disconnect = {}
            $0.widgetClient.updateConnection = { update in updates.withValue { $0.append(update) } }
        }

        await store.send(.connection(.disconnect)) {
            $0.connection.status = .disconnected
            $0.connection.connectedDevice = nil
        }
        await store.finish()

        #expect(updates.value == [.disconnected])
    }

    @Test("연결 상태 변환: 재연결 중에는 기기 이름을 유지하고 연결 중은 연결 안 됨으로 처리")
    func connectionStateMapping() {
        #expect(WidgetConnectionState(status: .connected(device)) == .connected(deviceName: "MacBook Pro"))
        #expect(
            WidgetConnectionState(status: .reconnecting(device, attempt: 1)) == .reconnecting(deviceName: "MacBook Pro")
        )
        #expect(WidgetConnectionState(status: .connecting(device)) == .disconnected)
        #expect(WidgetConnectionState(status: .discovering) == .disconnected)
    }

    @Test("재생 정보가 바뀌면 위젯에 재생 정보를 전달")
    func nowPlayingChangeUpdatesWidget() async {
        let updates = LockIsolated<[WidgetNowPlaying?]>([])
        let info = NowPlayingInfo(appName: "Music", title: "Song", artist: "Artist", album: "Album", isPlaying: true)

        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.widgetClient.updateNowPlaying = { update in updates.withValue { $0.append(update) } }
        }

        await store.send(.media(.nowPlayingInfoReceived(info))) {
            $0.media.nowPlayingInfo = info
            $0.media.isPlaying = true
        }
        await store.finish()

        #expect(updates.value == [
            WidgetNowPlaying(title: "Song", artist: "Artist", album: "Album", isPlaying: true, appName: "Music"),
        ])
    }

    @Test("제목 없는 재생 정보는 재생 항목 없음으로 처리")
    func emptyNowPlayingMapsToNil() {
        #expect(WidgetNowPlaying(info: NowPlayingInfo()) == nil)
    }
}
