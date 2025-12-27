# TCA 상태 트리 (State Tree)

| 버전 | v1.0.0 |
| --- | --- |
| **작성일** | 2025년 12월 27일 |
| **관련 문서** | PRD.md, ProtocolSpec.md |

---

## 1. 개요 (Overview)

iOS 앱은 The Composable Architecture (TCA) 패턴을 사용합니다. 이 문서는 앱의 전체 상태 트리와 각 Feature의 Reducer 구조를 정의합니다.

### 1.1 모듈 구조

```
AppFeature (Root)
├── ConnectionFeature
├── TabFeature
│   ├── EssentialsFeature
│   │   ├── TrackpadFeature
│   │   ├── KeyboardFeature
│   │   └── MediaFeature
│   ├── ProductivityFeature
│   │   ├── WindowSnapFeature
│   │   ├── AppSwitcherFeature
│   │   └── MacroPadFeature
│   └── PresenterFeature
│       ├── LaserPointerFeature
│       ├── PresentationFeature
│       └── VoiceTypingFeature
└── SettingsFeature
```

---

## 2. 루트 상태 (AppFeature)

```swift
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var connection: ConnectionFeature.State = .init()
        var tab: TabFeature.State = .init()
        var settings: SettingsFeature.State = .init()

        // 전역 상태
        var isOnboarded: Bool = false

        // 시트/모달
        @Presents var destination: Destination.State?
    }

    enum Action {
        case connection(ConnectionFeature.Action)
        case tab(TabFeature.Action)
        case settings(SettingsFeature.Action)
        case destination(PresentationAction<Destination.Action>)

        // 앱 라이프사이클
        case onAppear
        case scenePhaseChanged(ScenePhase)
    }

    @Reducer
    enum Destination {
        case settings(SettingsFeature)
        case connectionSheet(ConnectionSheetFeature)
    }
}
```

---

## 3. 연결 상태 (ConnectionFeature)

```swift
@Reducer
struct ConnectionFeature {
    @ObservableState
    struct State: Equatable {
        var status: ConnectionStatus = .disconnected
        var discoveredDevices: IdentifiedArrayOf<Device> = []
        var connectedDevice: Device?
        var lastError: ConnectionError?

        // 네트워크 품질
        var latency: TimeInterval = 0
        var signalStrength: SignalStrength = .unknown
    }

    enum Action {
        // 디스커버리
        case startDiscovery
        case stopDiscovery
        case deviceDiscovered(Device)
        case deviceLost(Device.ID)

        // 연결
        case connect(Device)
        case disconnect
        case connectionStatusChanged(ConnectionStatus)

        // 하트비트
        case heartbeatTick
        case heartbeatReceived(latency: TimeInterval)
        case heartbeatTimeout

        // 에러
        case errorOccurred(ConnectionError)
        case clearError
    }
}

// 연결 상태 열거형
enum ConnectionStatus: Equatable {
    case disconnected
    case discovering
    case connecting(Device)
    case connected(Device)
    case reconnecting(Device, attempt: Int)
}

// 디바이스 모델
struct Device: Equatable, Identifiable {
    let id: UUID
    let name: String
    let host: String
    let port: UInt16
}

// 신호 강도
enum SignalStrength: Equatable {
    case unknown
    case weak      // > 100ms
    case moderate  // 50-100ms
    case strong    // < 50ms
}
```

---

## 4. 탭 상태 (TabFeature)

```swift
@Reducer
struct TabFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .essentials
        var essentials: EssentialsFeature.State = .init()
        var productivity: ProductivityFeature.State = .init()
        var presenter: PresenterFeature.State = .init()
    }

    enum Tab: String, CaseIterable {
        case essentials
        case productivity
        case presenter
    }

    enum Action {
        case tabSelected(Tab)
        case essentials(EssentialsFeature.Action)
        case productivity(ProductivityFeature.Action)
        case presenter(PresenterFeature.Action)
    }
}
```

---

## 5. Mode 1: Essentials

### 5.1 EssentialsFeature

```swift
@Reducer
struct EssentialsFeature {
    @ObservableState
    struct State: Equatable {
        var trackpad: TrackpadFeature.State = .init()
        var keyboard: KeyboardFeature.State = .init()
        var media: MediaFeature.State = .init()
    }

    enum Action {
        case trackpad(TrackpadFeature.Action)
        case keyboard(KeyboardFeature.Action)
        case media(MediaFeature.Action)
    }
}
```

### 5.2 TrackpadFeature

```swift
@Reducer
struct TrackpadFeature {
    @ObservableState
    struct State: Equatable {
        var isActive: Bool = false
        var sensitivity: Double = 1.0
        var scrollSensitivity: Double = 1.0
        var isInertiaEnabled: Bool = true
        var isTapToClickEnabled: Bool = true

        // 제스처 상태 (UI 피드백용)
        var activeGesture: GestureType?
        var touchCount: Int = 0
    }

    enum GestureType: Equatable {
        case move
        case scroll
        case click(MouseButton)
        case drag
    }

    enum Action {
        // 터치 이벤트
        case touchBegan(TouchData)
        case touchMoved(TouchData)
        case touchEnded(TouchData)

        // 제스처 인식
        case gestureTap(count: Int)
        case gesturePan(delta: CGPoint)
        case gestureScroll(delta: CGPoint, isInertia: Bool)

        // 설정
        case setSensitivity(Double)
        case setScrollSensitivity(Double)
        case toggleInertia
        case toggleTapToClick
    }
}

struct TouchData: Equatable {
    let location: CGPoint
    let timestamp: TimeInterval
    let touchCount: Int
}
```

### 5.3 KeyboardFeature

```swift
@Reducer
struct KeyboardFeature {
    @ObservableState
    struct State: Equatable {
        var isKeyboardVisible: Bool = false
        var inputText: String = ""
        var activeModifiers: Set<Modifier> = []

        // 특수키 토글 상태
        var isCapsLockOn: Bool = false
    }

    enum Modifier: String, CaseIterable {
        case command
        case option
        case control
        case shift
    }

    enum Action {
        // 키보드 표시
        case showKeyboard
        case hideKeyboard

        // 입력
        case textChanged(String)
        case keyPressed(KeyCode)
        case keyReleased(KeyCode)

        // 모디파이어
        case modifierToggled(Modifier)
        case modifiersReset

        // 특수 동작
        case sendReturn
        case sendDelete
        case sendEscape
    }
}
```

### 5.4 MediaFeature

```swift
@Reducer
struct MediaFeature {
    @ObservableState
    struct State: Equatable {
        var volume: Double = 0.5
        var isMuted: Bool = false
        var isPlaying: Bool = false

        // 현재 재생 정보 (Mac에서 수신)
        var nowPlaying: NowPlayingInfo?
    }

    struct NowPlayingInfo: Equatable {
        let title: String?
        let artist: String?
        let albumArt: Data?
    }

    enum Action {
        // 재생 제어
        case playPause
        case nextTrack
        case previousTrack

        // 볼륨
        case setVolume(Double)
        case volumeUp
        case volumeDown
        case toggleMute

        // 물리 버튼 (아이폰 볼륨 버튼)
        case hardwareVolumeChanged(Double)

        // Mac에서 상태 수신
        case nowPlayingUpdated(NowPlayingInfo?)
        case volumeReceived(Double)
        case muteStateReceived(Bool)
    }
}
```

---

## 6. Mode 2: Productivity

### 6.1 ProductivityFeature

```swift
@Reducer
struct ProductivityFeature {
    @ObservableState
    struct State: Equatable {
        var windowSnap: WindowSnapFeature.State = .init()
        var appSwitcher: AppSwitcherFeature.State = .init()
        var macroPad: MacroPadFeature.State = .init()
    }

    enum Action {
        case windowSnap(WindowSnapFeature.Action)
        case appSwitcher(AppSwitcherFeature.Action)
        case macroPad(MacroPadFeature.Action)
    }
}
```

### 6.2 WindowSnapFeature

```swift
@Reducer
struct WindowSnapFeature {
    @ObservableState
    struct State: Equatable {
        var lastUsedPosition: SnapPosition?
    }

    enum SnapPosition: String, CaseIterable {
        case leftHalf
        case rightHalf
        case topHalf
        case bottomHalf
        case fullScreen
        case center
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    enum Action {
        case snapTo(SnapPosition)
        case snapCompleted
        case snapFailed(Error)
    }
}
```

### 6.3 AppSwitcherFeature

```swift
@Reducer
struct AppSwitcherFeature {
    @ObservableState
    struct State: Equatable {
        var apps: IdentifiedArrayOf<AppInfo> = []
        var isLoading: Bool = false
        var selectedAppID: AppInfo.ID?
    }

    struct AppInfo: Equatable, Identifiable {
        let id: UUID
        let bundleID: String
        let name: String
        let icon: Data?
        let isActive: Bool
        let pid: UInt32
    }

    enum Action {
        // 앱 목록
        case refresh
        case appsReceived([AppInfo])
        case refreshFailed(Error)

        // 앱 전환
        case appSelected(AppInfo.ID)
        case focusApp(AppInfo)
        case focusCompleted
        case focusFailed(Error)
    }
}
```

### 6.4 MacroPadFeature

```swift
@Reducer
struct MacroPadFeature {
    @ObservableState
    struct State: Equatable {
        var macros: IdentifiedArrayOf<Macro> = .defaultMacros
        var isEditing: Bool = false
    }

    struct Macro: Equatable, Identifiable {
        let id: UUID
        var name: String
        var icon: String  // SF Symbol name
        var keyCombo: KeyCombo
        var color: MacroColor
    }

    struct KeyCombo: Equatable {
        var keyCodes: [UInt32]
        var modifiers: Set<KeyboardFeature.Modifier>
    }

    enum MacroColor: String, CaseIterable {
        case blue, green, orange, red, purple, yellow
    }

    enum Action {
        // 실행
        case executeMacro(Macro.ID)
        case macroExecuted(Macro.ID)
        case macroFailed(Macro.ID, Error)

        // 편집
        case startEditing
        case stopEditing
        case addMacro(Macro)
        case updateMacro(Macro)
        case deleteMacro(Macro.ID)
        case reorderMacros(from: IndexSet, to: Int)
    }
}

extension IdentifiedArrayOf where Element == MacroPadFeature.Macro {
    static let defaultMacros: Self = [
        .init(id: UUID(), name: "Copy", icon: "doc.on.doc",
              keyCombo: .init(keyCodes: [8], modifiers: [.command]), color: .blue),
        .init(id: UUID(), name: "Paste", icon: "doc.on.clipboard",
              keyCombo: .init(keyCodes: [9], modifiers: [.command]), color: .green),
        .init(id: UUID(), name: "Undo", icon: "arrow.uturn.backward",
              keyCombo: .init(keyCodes: [6], modifiers: [.command]), color: .orange),
        .init(id: UUID(), name: "Screenshot", icon: "camera.viewfinder",
              keyCombo: .init(keyCodes: [21], modifiers: [.command, .shift]), color: .purple),
    ]
}
```

---

## 7. Mode 3: Presenter

### 7.1 PresenterFeature

```swift
@Reducer
struct PresenterFeature {
    @ObservableState
    struct State: Equatable {
        var laserPointer: LaserPointerFeature.State = .init()
        var presentation: PresentationFeature.State = .init()
        var voiceTyping: VoiceTypingFeature.State = .init()
    }

    enum Action {
        case laserPointer(LaserPointerFeature.Action)
        case presentation(PresentationFeature.Action)
        case voiceTyping(VoiceTypingFeature.Action)
    }
}
```

### 7.2 LaserPointerFeature

```swift
@Reducer
struct LaserPointerFeature {
    @ObservableState
    struct State: Equatable {
        var isActive: Bool = false
        var sensitivity: Double = 1.0
        var calibrationOffset: SIMD3<Double> = .zero

        // 모션 데이터
        var currentAttitude: SIMD3<Double> = .zero  // roll, pitch, yaw
        var currentRotationRate: SIMD3<Double> = .zero
    }

    enum Action {
        // 활성화
        case activate
        case deactivate

        // 캘리브레이션
        case calibrate
        case calibrationCompleted(offset: SIMD3<Double>)

        // 모션 업데이트
        case motionUpdated(attitude: SIMD3<Double>, rotationRate: SIMD3<Double>)

        // 설정
        case setSensitivity(Double)
    }
}
```

### 7.3 PresentationFeature

```swift
@Reducer
struct PresentationFeature {
    @ObservableState
    struct State: Equatable {
        var isPresenting: Bool = false
        var currentSlide: Int = 0
        var totalSlides: Int?

        // 타이머
        var timerDuration: TimeInterval = 0
        var isTimerRunning: Bool = false
        var elapsedTime: TimeInterval = 0
    }

    enum Action {
        // 슬라이드 제어
        case nextSlide
        case previousSlide
        case goToSlide(Int)

        // 프레젠테이션 모드
        case startPresentation
        case endPresentation
        case blankScreen

        // 타이머
        case startTimer(duration: TimeInterval)
        case stopTimer
        case resetTimer
        case timerTick

        // Mac 상태 수신
        case slideInfoReceived(current: Int, total: Int?)
    }
}
```

### 7.4 VoiceTypingFeature

```swift
@Reducer
struct VoiceTypingFeature {
    @ObservableState
    struct State: Equatable {
        var isRecording: Bool = false
        var recognizedText: String = ""
        var interimText: String = ""  // 인식 중인 텍스트
        var permissionStatus: PermissionStatus = .notDetermined
        var errorMessage: String?
    }

    enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
    }

    enum Action {
        // 권한
        case checkPermission
        case permissionUpdated(PermissionStatus)
        case requestPermission

        // 녹음
        case startRecording
        case stopRecording
        case cancelRecording

        // 인식 결과
        case interimResultReceived(String)
        case finalResultReceived(String)
        case recognitionFailed(Error)

        // 전송
        case sendText
        case textSent
        case clearText
    }
}
```

---

## 8. 설정 상태 (SettingsFeature)

```swift
@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        // 트랙패드 설정
        var trackpadSensitivity: Double = 1.0
        var scrollSensitivity: Double = 1.0
        var isNaturalScrolling: Bool = true
        var isTapToClick: Bool = true

        // 레이저 포인터 설정
        var laserSensitivity: Double = 1.0

        // 햅틱 설정
        var isHapticEnabled: Bool = true
        var hapticIntensity: HapticIntensity = .medium

        // 테마
        var accentColor: AccentColor = .lime
    }

    enum HapticIntensity: String, CaseIterable {
        case light, medium, heavy
    }

    enum AccentColor: String, CaseIterable {
        case lime, cyan, purple, orange
    }

    enum Action {
        case setTrackpadSensitivity(Double)
        case setScrollSensitivity(Double)
        case toggleNaturalScrolling
        case toggleTapToClick
        case setLaserSensitivity(Double)
        case toggleHaptic
        case setHapticIntensity(HapticIntensity)
        case setAccentColor(AccentColor)
        case resetToDefaults
    }
}
```

---

## 9. Dependencies

```swift
@DependencyClient
struct NetworkClient {
    var connect: @Sendable (Device) async throws -> Void
    var disconnect: @Sendable () async -> Void
    var sendUDP: @Sendable (Data) async -> Void
    var sendTCP: @Sendable (Data) async throws -> Void
    var receiveMessages: @Sendable () -> AsyncStream<ServerMessage>
}

@DependencyClient
struct DiscoveryClient {
    var start: @Sendable () async -> AsyncStream<DiscoveryEvent>
    var stop: @Sendable () async -> Void
}

@DependencyClient
struct MotionClient {
    var start: @Sendable () async -> AsyncStream<MotionData>
    var stop: @Sendable () async -> Void
}

@DependencyClient
struct SpeechClient {
    var requestPermission: @Sendable () async -> Bool
    var startRecognition: @Sendable () async -> AsyncStream<SpeechResult>
    var stopRecognition: @Sendable () async -> Void
}

@DependencyClient
struct HapticClient {
    var impact: @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) async -> Void
    var notification: @Sendable (UINotificationFeedbackGenerator.FeedbackType) async -> Void
    var selection: @Sendable () async -> Void
}

@DependencyClient
struct UserDefaultsClient {
    var get: @Sendable (String) -> Data?
    var set: @Sendable (String, Data?) async -> Void
}
```

---

## 10. 상태 다이어그램 (State Diagram)

### 10.1 연결 상태 흐름

```
                    ┌─────────────┐
                    │ Disconnected│
                    └──────┬──────┘
                           │ startDiscovery
                           ▼
                    ┌─────────────┐
              ┌─────│ Discovering │◄────────┐
              │     └──────┬──────┘         │
              │            │ connect(device)│
              │            ▼                │
              │     ┌─────────────┐         │
              │     │ Connecting  │─────────┤ timeout
              │     └──────┬──────┘         │
              │            │ success        │
              │            ▼                │
              │     ┌─────────────┐         │
disconnect    └────►│  Connected  │─────────┘
                    └──────┬──────┘  heartbeat
                           │         timeout
                           ▼
                    ┌─────────────┐
                    │ Reconnecting│──► (3회 실패 시 Disconnected)
                    └─────────────┘
```
