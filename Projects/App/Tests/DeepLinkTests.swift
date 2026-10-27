import ComposableArchitecture
import Foundation
import Testing
@testable import App

@Suite("딥링크 테스트")
struct DeepLinkTests {
    private let device = Device(id: "mac-1", name: "MacBook Pro", host: "192.168.0.2", port: 9000)

    @Test("snap://media는 미디어 탭을 연다")
    func mediaOpensMediaTab() async throws {
        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.handleURL(try #require(URL(string: "snap://media")))) {
            $0.selectedTab = .media
        }
    }

    @Test("snap://media/playpause는 미디어 탭을 열고 재생 명령을 보낸다")
    func mediaCommandSendsControl() async throws {
        let sent = LockIsolated<[MediaControl.Command]>([])
        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, _ in sent.withValue { $0.append(command) } }
        }

        await store.send(.handleURL(try #require(URL(string: "snap://media/playpause")))) {
            $0.selectedTab = .media
        }
        await store.receive(\.media.playPauseTapped) {
            $0.media.isPlaying = true
        }
        await store.finish()

        #expect(sent.value == [.playPause])
    }

    @Test("snap://media/mute는 음소거 명령을 보낸다")
    func muteCommandSendsControl() async throws {
        let sent = LockIsolated<[MediaControl.Command]>([])
        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, _ in sent.withValue { $0.append(command) } }
        }

        await store.send(.handleURL(try #require(URL(string: "snap://media/mute")))) {
            $0.selectedTab = .media
        }
        await store.receive(\.media.muteTapped) {
            $0.media.isMuted = true
        }
        await store.finish()

        #expect(sent.value == [.mute])
    }

    @Test("snap://connect는 마지막 Mac이 있으면 다시 연결한다")
    func connectReconnectsLastDevice() async throws {
        var state = AppFeature.State()
        state.connection.lastConnectedDevice = device

        let store = await TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.connectionClient.connect = { _, _, _ in .finished }
        }

        await store.send(.handleURL(try #require(URL(string: "snap://connect"))))
        await store.receive(\.connection.connect) {
            $0.connection.status = .connecting(device)
        }
        await store.finish()
    }

    @Test("snap://connect는 마지막 Mac이 없으면 연결 화면을 연다")
    func connectShowsConnectionSheet() async throws {
        let store = await TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.handleURL(try #require(URL(string: "snap://connect")))) {
            $0.isConnectionSheetPresented = true
        }
    }

    @Test("snap://disconnect는 연결을 끊는다")
    func disconnectDisconnects() async throws {
        var state = AppFeature.State()
        state.connection.status = .connected(device)
        state.connection.connectedDevice = device

        let store = await TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.connectionClient.disconnect = {}
        }

        await store.send(.handleURL(try #require(URL(string: "snap://disconnect"))))
        await store.receive(\.connection.disconnect) {
            $0.connection.status = .disconnected
            $0.connection.connectedDevice = nil
        }
        await store.finish()
    }
}
