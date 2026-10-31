import Shared
import Testing
@testable import MacReceiver

@Suite("Volume state")
struct VolumeStateTests {
    @Test func parsesAppleScriptVolumeSettings() {
        #expect(MediaController.parseVolumeSettings("44,false") == VolumeState(volume: 0.44, isMuted: false))
        #expect(MediaController.parseVolumeSettings("100, true") == VolumeState(volume: 1, isMuted: true))
    }

    @Test func ignoresDevicesWithoutVolume() {
        #expect(MediaController.parseVolumeSettings("missing value,false") == nil)
        #expect(MediaController.parseVolumeSettings("") == nil)
    }
}
