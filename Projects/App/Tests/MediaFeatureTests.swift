import ComposableArchitecture
import Testing
@testable import App
import Shared

// MARK: - Playback Control Tests

@Suite("재생 제어 테스트")
struct PlaybackControlTests {
    @Test("재생/정지 토글 - 재생 중 → 정지")
    func playPauseTappedWhilePlaying() async {
        var state = MediaFeature.State()
        state.isPlaying = true

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.playPauseTapped) {
            $0.isPlaying = false
        }

        #expect(sentMediaControl.value?.0 == .playPause)
    }

    @Test("재생/정지 토글 - 정지 → 재생")
    func playPauseTappedWhilePaused() async {
        var state = MediaFeature.State()
        state.isPlaying = false

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.playPauseTapped) {
            $0.isPlaying = true
        }

        #expect(sentMediaControl.value?.0 == .playPause)
    }

    @Test("다음 트랙")
    func nextTrackTapped() async {
        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: MediaFeature.State()) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.nextTrackTapped)

        #expect(sentMediaControl.value?.0 == .nextTrack)
    }

    @Test("이전 트랙")
    func previousTrackTapped() async {
        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: MediaFeature.State()) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.previousTrackTapped)

        #expect(sentMediaControl.value?.0 == .prevTrack)
    }
}

// MARK: - Volume Control Tests

@Suite("볼륨 제어 테스트")
struct VolumeControlTests {
    @Test("볼륨 업 - 0.1 증가")
    func volumeUpTapped() async {
        var state = MediaFeature.State()
        state.volume = 0.5

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.volumeUpTapped) {
            $0.volume = 0.6
        }

        #expect(sentMediaControl.value?.0 == .volumeUp)
        #expect(abs((sentMediaControl.value?.1 ?? 0) - 0.6) < 0.001)
    }

    @Test("볼륨 업 - 최대 1.0 제한")
    func volumeUpTappedAtMax() async {
        var state = MediaFeature.State()
        state.volume = 0.95

        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { _, _ in }
        }

        await store.send(.volumeUpTapped) {
            $0.volume = 1.0
        }
    }

    @Test("볼륨 업 시 음소거 해제")
    func volumeUpUnmutes() async {
        var state = MediaFeature.State()
        state.volume = 0.5
        state.isMuted = true

        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { _, _ in }
        }

        await store.send(.volumeUpTapped) {
            $0.volume = 0.6
            $0.isMuted = false
        }
    }

    @Test("볼륨 다운 - 0.1 감소")
    func volumeDownTapped() async {
        var state = MediaFeature.State()
        state.volume = 0.5

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.volumeDownTapped) {
            $0.volume = 0.4
        }

        #expect(sentMediaControl.value?.0 == .volumeDown)
        #expect(abs((sentMediaControl.value?.1 ?? 0) - 0.4) < 0.001)
    }

    @Test("볼륨 다운 - 최소 0.0 제한")
    func volumeDownTappedAtMin() async {
        var state = MediaFeature.State()
        state.volume = 0.05

        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { _, _ in }
        }

        await store.send(.volumeDownTapped) {
            $0.volume = 0.0
        }
    }

    @Test("음소거 토글 - 활성화")
    func muteTapped() async {
        var state = MediaFeature.State()
        state.isMuted = false

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.muteTapped) {
            $0.isMuted = true
        }

        #expect(sentMediaControl.value?.0 == .mute)
    }

    @Test("음소거 토글 - 비활성화")
    func muteUnmute() async {
        var state = MediaFeature.State()
        state.isMuted = true

        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { _, _ in }
        }

        await store.send(.muteTapped) {
            $0.isMuted = false
        }
    }

    @Test("볼륨 직접 변경")
    func volumeChanged() async {
        var state = MediaFeature.State()
        state.volume = 0.5

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.volumeChanged(0.7)) {
            $0.volume = 0.7
        }

        #expect(sentMediaControl.value?.0 == .setVolume)
        #expect(abs((sentMediaControl.value?.1 ?? 0) - 0.7) < 0.001)
    }

    @Test("볼륨 변경 시 음소거 해제")
    func volumeChangedUnmutes() async {
        var state = MediaFeature.State()
        state.volume = 0.0
        state.isMuted = true

        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { _, _ in }
        }

        await store.send(.volumeChanged(0.5)) {
            $0.volume = 0.5
            $0.isMuted = false
        }
    }

    @Test("볼륨 0으로 변경 시 음소거 유지")
    func volumeChangedToZeroKeepsMute() async {
        var state = MediaFeature.State()
        state.volume = 0.5
        state.isMuted = true

        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { _, _ in }
        }

        await store.send(.volumeChanged(0.0)) {
            $0.volume = 0.0
            // isMuted는 그대로 유지 (볼륨이 0보다 크지 않으므로)
        }
    }
}

// MARK: - Hardware Volume Control Tests

@Suite("하드웨어 볼륨 버튼 테스트")
struct HardwareVolumeControlTests {
    @Test("하드웨어 볼륨 업 - 활성화 시")
    func hardwareVolumeUp() async {
        var state = MediaFeature.State()
        state.isHardwareVolumeControlEnabled = true
        state.volume = 0.5

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.hardwareVolumeUp) {
            $0.volume = 0.6
        }

        #expect(sentMediaControl.value?.0 == .volumeUp)
    }

    @Test("하드웨어 볼륨 업 - 비활성화 시 무시")
    func hardwareVolumeUpDisabled() async {
        var state = MediaFeature.State()
        state.isHardwareVolumeControlEnabled = false
        state.volume = 0.5

        let store = await TestStore(initialState: state) {
            MediaFeature()
        }

        await store.send(.hardwareVolumeUp)
        // 상태 변화 없음
    }

    @Test("하드웨어 볼륨 다운 - 활성화 시")
    func hardwareVolumeDown() async {
        var state = MediaFeature.State()
        state.isHardwareVolumeControlEnabled = true
        state.volume = 0.5

        let sentMediaControl = LockIsolated<(MediaControl.Command, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { command, volume in
                sentMediaControl.setValue((command, volume))
            }
        }

        await store.send(.hardwareVolumeDown) {
            $0.volume = 0.4
        }

        #expect(sentMediaControl.value?.0 == .volumeDown)
    }

    @Test("하드웨어 볼륨 다운 - 비활성화 시 무시")
    func hardwareVolumeDownDisabled() async {
        var state = MediaFeature.State()
        state.isHardwareVolumeControlEnabled = false
        state.volume = 0.5

        let store = await TestStore(initialState: state) {
            MediaFeature()
        }

        await store.send(.hardwareVolumeDown)
        // 상태 변화 없음
    }

    @Test("하드웨어 볼륨 컨트롤 활성화/비활성화")
    func setHardwareVolumeControlEnabled() async {
        var state = MediaFeature.State()
        state.isHardwareVolumeControlEnabled = true

        let store = await TestStore(initialState: state) {
            MediaFeature()
        }

        await store.send(.setHardwareVolumeControlEnabled(false)) {
            $0.isHardwareVolumeControlEnabled = false
        }

        await store.send(.setHardwareVolumeControlEnabled(true)) {
            $0.isHardwareVolumeControlEnabled = true
        }
    }

    @Test("하드웨어 볼륨 업 시 음소거 해제")
    func hardwareVolumeUpUnmutes() async {
        var state = MediaFeature.State()
        state.isHardwareVolumeControlEnabled = true
        state.volume = 0.5
        state.isMuted = true

        let store = await TestStore(initialState: state) {
            MediaFeature()
        } withDependencies: {
            $0.connectionClient.sendMediaControl = { _, _ in }
        }

        await store.send(.hardwareVolumeUp) {
            $0.volume = 0.6
            $0.isMuted = false
        }
    }
}

// MARK: - State Update Tests

@Suite("상태 업데이트 테스트")
struct StateUpdateTests {
    @Test("재생 상태 설정")
    func setIsPlaying() async {
        let store = await TestStore(initialState: MediaFeature.State()) {
            MediaFeature()
        }

        await store.send(.setIsPlaying(true)) {
            $0.isPlaying = true
        }

        await store.send(.setIsPlaying(false)) {
            $0.isPlaying = false
        }
    }

    @Test("NowPlaying 정보 수신")
    func nowPlayingInfoReceived() async {
        let nowPlayingInfo = NowPlayingInfo(
            appName: "Music",
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            isPlaying: true,
            artworkData: nil
        )

        let store = await TestStore(initialState: MediaFeature.State()) {
            MediaFeature()
        }

        await store.send(.nowPlayingInfoReceived(nowPlayingInfo)) {
            $0.nowPlayingInfo = nowPlayingInfo
            $0.isPlaying = true
        }
    }

    @Test("NowPlaying 정보 수신 - 재생 상태 동기화")
    func nowPlayingInfoSyncsPlayingState() async {
        var state = MediaFeature.State()
        state.isPlaying = true

        let nowPlayingInfo = NowPlayingInfo(
            appName: "Spotify",
            title: "Another Song",
            artist: "Another Artist",
            album: "Another Album",
            isPlaying: false,
            artworkData: nil
        )

        let store = await TestStore(initialState: state) {
            MediaFeature()
        }

        await store.send(.nowPlayingInfoReceived(nowPlayingInfo)) {
            $0.nowPlayingInfo = nowPlayingInfo
            $0.isPlaying = false // NowPlaying 정보에 맞춰 동기화
        }
    }
}
