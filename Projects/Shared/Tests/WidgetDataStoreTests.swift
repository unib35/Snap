import Foundation
@testable import Shared
import Testing

@Suite("WidgetDataStore Tests")
struct WidgetDataStoreTests {
    private func makeStore() -> WidgetDataStore {
        let suiteName = "WidgetDataStoreTests.\(UUID().uuidString)"
        return WidgetDataStore(userDefaults: UserDefaults(suiteName: suiteName))
    }

    @Test("연결 상태 저장과 읽기")
    func connectionStatusRoundTrip() {
        let store = makeStore()
        #expect(store.isConnected == false)
        #expect(store.connectedDeviceName == nil)

        store.updateConnectionStatus(isConnected: true, deviceName: "MacBook Pro")
        #expect(store.isConnected == true)
        #expect(store.connectedDeviceName == "MacBook Pro")

        store.updateConnectionStatus(isConnected: false, deviceName: nil)
        #expect(store.isConnected == false)
        #expect(store.connectedDeviceName == nil)
    }

    @Test("매크로 저장과 읽기")
    func macrosRoundTrip() {
        let store = makeStore()
        let macro = Macro(name: "복사", icon: "doc.on.doc", color: .green, keyCombo: KeyCombo(keyCodes: [8]))
        let items = [WidgetMacroItem(macro: macro)]

        store.saveMacros(items)

        #expect(store.loadMacros() == items)
        #expect(store.loadMacros().first?.colorName == "green")
    }

    @Test("재생 정보 저장, 읽기, 삭제")
    func nowPlayingRoundTrip() {
        let store = makeStore()
        let nowPlaying = WidgetNowPlaying(title: "Song", artist: "Artist", album: "", isPlaying: true, appName: "Music")

        store.saveNowPlaying(nowPlaying)
        #expect(store.loadNowPlaying() == nowPlaying)

        store.saveNowPlaying(nil)
        #expect(store.loadNowPlaying() == nil)
    }
}
