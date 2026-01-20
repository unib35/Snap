import ComposableArchitecture
import CoreGraphics
import Testing
@testable import App
import Shared

// MARK: - Touch Event Tests

@Suite("터치 이벤트 테스트")
struct TouchEventTests {
    @Test("터치 시작 시 상태 업데이트")
    func touchBegan() async {
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        }

        await store.send(.touchBegan(CGPoint(x: 100, y: 100))) {
            $0.isTouching = true
            $0.lastTouchPosition = CGPoint(x: 100, y: 100)
        }
    }

    @Test("터치 이동 시 마우스 이동 전송")
    func touchMoved() async {
        var state = TrackpadFeature.State()
        state.isTouching = true
        state.lastTouchPosition = CGPoint(x: 100, y: 100)
        state.sensitivity = 1.0

        let sentDeltas = LockIsolated<(Float, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseMove = { dx, dy in
                sentDeltas.setValue((dx, dy))
            }
        }

        await store.send(.touchMoved(CGPoint(x: 110, y: 105))) {
            $0.lastTouchPosition = CGPoint(x: 110, y: 105)
        }

        #expect(sentDeltas.value?.0 == 10.0)
        #expect(sentDeltas.value?.1 == 5.0)
    }

    @Test("터치 중이 아니면 이동 무시")
    func touchMovedWhileNotTouching() async {
        let state = TrackpadFeature.State()

        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        }

        await store.send(.touchMoved(CGPoint(x: 110, y: 105)))
        // 상태 변화 없음
    }

    @Test("터치 종료 시 상태 초기화")
    func touchEnded() async {
        var state = TrackpadFeature.State()
        state.isTouching = true
        state.lastTouchPosition = CGPoint(x: 100, y: 100)

        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        }

        await store.send(.touchEnded) {
            $0.isTouching = false
        }
    }

    @Test("감도 적용 테스트")
    func sensitivityApplied() async {
        var state = TrackpadFeature.State()
        state.isTouching = true
        state.lastTouchPosition = CGPoint(x: 100, y: 100)
        state.sensitivity = 2.0

        let sentDeltas = LockIsolated<(Float, Float)?>(nil)
        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseMove = { dx, dy in
                sentDeltas.setValue((dx, dy))
            }
        }

        await store.send(.touchMoved(CGPoint(x: 110, y: 100))) {
            $0.lastTouchPosition = CGPoint(x: 110, y: 100)
        }

        #expect(sentDeltas.value?.0 == 20.0) // 10 * 2.0 = 20
        #expect(sentDeltas.value?.1 == 0.0)
    }
}

// MARK: - Gesture Tests

@Suite("제스처 테스트")
struct GestureTests {
    @Test("탭 - TapToClick 활성화 시 클릭 전송")
    func tapped() async {
        var state = TrackpadFeature.State()
        state.isTapToClick = true

        let sentClick = LockIsolated<(MouseClick.Button, MouseClick.Action)?>(nil)
        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseClick = { button, action in
                sentClick.setValue((button, action))
            }
        }

        await store.send(.tapped)

        #expect(sentClick.value?.0 == .left)
        #expect(sentClick.value?.1 == .click)
    }

    @Test("탭 - TapToClick 비활성화 시 무시")
    func tappedWithTapToClickDisabled() async {
        var state = TrackpadFeature.State()
        state.isTapToClick = false

        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        }

        await store.send(.tapped)
        // 아무 동작 없음
    }

    @Test("더블탭 - 더블클릭 전송")
    func doubleTapped() async {
        let sentClick = LockIsolated<(MouseClick.Button, MouseClick.Action)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseClick = { button, action in
                sentClick.setValue((button, action))
            }
        }

        await store.send(.doubleTapped)

        #expect(sentClick.value?.0 == .left)
        #expect(sentClick.value?.1 == .double)
    }

    @Test("두 손가락 탭 - 우클릭 전송")
    func twoFingerTapped() async {
        let sentClick = LockIsolated<(MouseClick.Button, MouseClick.Action)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseClick = { button, action in
                sentClick.setValue((button, action))
            }
        }

        await store.send(.twoFingerTapped)

        #expect(sentClick.value?.0 == .right)
        #expect(sentClick.value?.1 == .click)
    }

    @Test("스크롤 - 자연스러운 스크롤 활성화")
    func scrolledNatural() async {
        var state = TrackpadFeature.State()
        state.isNaturalScrolling = true
        state.scrollSensitivity = 1.0

        let sentScroll = LockIsolated<(Float, Float, Bool)?>(nil)
        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendScroll = { dx, dy, isInertia in
                sentScroll.setValue((dx, dy, isInertia))
            }
        }

        await store.send(.scrolled(deltaX: 10, deltaY: 20))

        #expect(sentScroll.value?.0 == 10.0)
        #expect(sentScroll.value?.1 == 20.0)
        #expect(sentScroll.value?.2 == false)
    }

    @Test("스크롤 - 자연스러운 스크롤 비활성화 시 Y 반전")
    func scrolledReversed() async {
        var state = TrackpadFeature.State()
        state.isNaturalScrolling = false
        state.scrollSensitivity = 1.0

        let sentScroll = LockIsolated<(Float, Float, Bool)?>(nil)
        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendScroll = { dx, dy, isInertia in
                sentScroll.setValue((dx, dy, isInertia))
            }
        }

        await store.send(.scrolled(deltaX: 10, deltaY: 20))

        #expect(sentScroll.value?.0 == 10.0)
        #expect(sentScroll.value?.1 == -20.0) // 반전됨
    }

    @Test("스크롤 감도 적용")
    func scrollSensitivityApplied() async {
        var state = TrackpadFeature.State()
        state.isNaturalScrolling = true
        state.scrollSensitivity = 2.0

        let sentScroll = LockIsolated<(Float, Float, Bool)?>(nil)
        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendScroll = { dx, dy, isInertia in
                sentScroll.setValue((dx, dy, isInertia))
            }
        }

        await store.send(.scrolled(deltaX: 10, deltaY: 10))

        #expect(sentScroll.value?.0 == 20.0) // 10 * 2.0
        #expect(sentScroll.value?.1 == 20.0) // 10 * 2.0
    }

    @Test("핀치 제스처 전송")
    func pinched() async {
        let sentPinch = LockIsolated<(Float, Pinch.Phase)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendPinch = { scale, phase in
                sentPinch.setValue((scale, phase))
            }
        }

        await store.send(.pinched(scale: 1.5, phase: .began))

        #expect(sentPinch.value?.0 == 1.5)
        #expect(sentPinch.value?.1 == .began)
    }
}

// MARK: - Click Button Tests

@Suite("클릭 버튼 테스트")
struct ClickButtonTests {
    @Test("좌클릭 버튼 누름")
    func leftClickPressed() async {
        let sentClick = LockIsolated<(MouseClick.Button, MouseClick.Action)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseClick = { button, action in
                sentClick.setValue((button, action))
            }
        }

        await store.send(.leftClickPressed)

        #expect(sentClick.value?.0 == .left)
        #expect(sentClick.value?.1 == .down)
    }

    @Test("좌클릭 버튼 뗌")
    func leftClickReleased() async {
        let sentClick = LockIsolated<(MouseClick.Button, MouseClick.Action)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseClick = { button, action in
                sentClick.setValue((button, action))
            }
        }

        await store.send(.leftClickReleased)

        #expect(sentClick.value?.0 == .left)
        #expect(sentClick.value?.1 == .up)
    }

    @Test("우클릭 버튼 누름")
    func rightClickPressed() async {
        let sentClick = LockIsolated<(MouseClick.Button, MouseClick.Action)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseClick = { button, action in
                sentClick.setValue((button, action))
            }
        }

        await store.send(.rightClickPressed)

        #expect(sentClick.value?.0 == .right)
        #expect(sentClick.value?.1 == .down)
    }

    @Test("우클릭 버튼 뗌")
    func rightClickReleased() async {
        let sentClick = LockIsolated<(MouseClick.Button, MouseClick.Action)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendMouseClick = { button, action in
                sentClick.setValue((button, action))
            }
        }

        await store.send(.rightClickReleased)

        #expect(sentClick.value?.0 == .right)
        #expect(sentClick.value?.1 == .up)
    }
}

// MARK: - Settings Tests

@Suite("설정 테스트")
struct TrackpadSettingsTests {
    @Test("설정 업데이트")
    func updateSettings() async {
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        }

        await store.send(.updateSettings(
            sensitivity: 1.5,
            scrollSensitivity: 2.0,
            isNaturalScrolling: false,
            isTapToClick: false
        )) {
            $0.sensitivity = 1.5
            $0.scrollSensitivity = 2.0
            $0.isNaturalScrolling = false
            $0.isTapToClick = false
        }
    }
}

// MARK: - Mode Tests

@Suite("모드 테스트")
struct ModeTests {
    @Test("트랙패드 모드로 변경")
    func changeToTrackpadMode() async {
        var state = TrackpadFeature.State()
        state.mode = .laser

        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        }

        await store.send(.modeChanged(.trackpad)) {
            $0.mode = .trackpad
        }
    }

    @Test("레이저 모드로 변경")
    func changeToLaserMode() async {
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        }

        await store.send(.modeChanged(.laser)) {
            $0.mode = .laser
        }
    }

    @Test("트랙패드 모드로 변경 시 레이저 포인터 중지")
    func changeToTrackpadStopsLaser() async {
        var state = TrackpadFeature.State()
        state.mode = .laser
        state.laserPointer.isActive = true

        let store = await TestStore(initialState: state) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendGyroData = { _ in }
        }

        await store.send(.modeChanged(.trackpad)) {
            $0.mode = .trackpad
        }

        await store.receive(\.laserPointer.stopPointing) {
            $0.laserPointer.isActive = false
        }
    }
}

// MARK: - Quick Action Tests

@Suite("퀵 액션 테스트")
struct QuickActionTests {
    @Test("미션 컨트롤 실행")
    func missionControlPressed() async {
        let sentKeyCombo = LockIsolated<([UInt32], UInt32)?>(nil)
        let store = await TestStore(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyCombo = { keyCodes, modifiers in
                sentKeyCombo.setValue((keyCodes, modifiers))
            }
        }

        await store.send(.missionControlPressed)

        #expect(sentKeyCombo.value?.0 == [126]) // Up Arrow
        #expect(sentKeyCombo.value?.1 == 0x02) // Control modifier
    }
}
