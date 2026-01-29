import Foundation
import ComposableArchitecture
import Shared

// MARK: - ConnectionClient

/// Mac과의 네트워크 연결을 관리하는 TCA 의존성 클라이언트.
///
/// `ConnectionClient`는 Snap 앱의 핵심 네트워크 계층으로, Bonjour 기반 디바이스 탐색,
/// TCP/UDP 연결 관리, 그리고 다양한 입력 이벤트 전송 기능을 제공합니다.
///
/// ## 주요 기능
/// - **디바이스 탐색**: Bonjour를 통한 로컬 네트워크 Mac 탐색
/// - **연결 관리**: TCP 연결 수립/해제 및 재연결
/// - **입력 전송**: 마우스, 키보드, 미디어 컨트롤 등 입력 이벤트 전송
/// - **페어링**: PIN 코드 기반 디바이스 인증
///
/// ## 사용 예제
/// ```swift
/// @Dependency(\.connectionClient) var connectionClient
///
/// // 디바이스 탐색 시작
/// for await event in await connectionClient.startDiscovery() {
///     switch event {
///     case .deviceFound(let device):
///         print("발견: \(device.name)")
///     case .deviceLost(let id):
///         print("연결 해제: \(id)")
///     case .error(let message):
///         print("오류: \(message)")
///     }
/// }
///
/// // Mac에 연결
/// let events = try await connectionClient.connect(device.host, device.port)
/// for await event in events {
///     // 연결 이벤트 처리
/// }
///
/// // 마우스 이동 전송
/// await connectionClient.sendMouseMove(deltaX, deltaY)
/// ```
///
/// ## 네트워크 프로토콜
/// - **UDP**: 마우스 이동, 스크롤, 자이로 데이터 (저지연, 손실 허용)
/// - **TCP**: 키보드 입력, 미디어 컨트롤, 시스템 명령 (신뢰성 보장)
///
/// - Note: 마우스 이동과 스크롤 이벤트는 내부적으로 배치 처리되어
///   네트워크 효율성을 최적화합니다.
public struct ConnectionClient: Sendable {
    // MARK: - Discovery

    /// Bonjour를 통한 로컬 네트워크 Mac 탐색을 시작합니다.
    ///
    /// - Returns: 디바이스 탐색 이벤트를 방출하는 `AsyncStream`.
    ///   스트림은 `stopDiscovery()` 호출 시 종료됩니다.
    public var startDiscovery: @Sendable () async -> AsyncStream<DiscoveryEvent>

    /// 디바이스 탐색을 중지합니다.
    public var stopDiscovery: @Sendable () async -> Void

    // MARK: - Connection

    /// 지정된 호스트와 포트로 Mac에 연결합니다.
    ///
    /// - Parameters:
    ///   - host: Mac의 IP 주소 또는 호스트명
    ///   - port: TCP 연결 포트 번호
    /// - Returns: 연결 상태 이벤트를 방출하는 `AsyncStream`
    /// - Throws: 연결 실패 시 에러
    public var connect: @Sendable (String, UInt16) async throws -> AsyncStream<ConnectionEvent>

    /// 현재 연결을 해제합니다.
    public var disconnect: @Sendable () async -> Void

    // MARK: - Mouse Input

    /// 마우스 커서 이동 이벤트를 전송합니다.
    ///
    /// - Parameters:
    ///   - deltaX: X축 이동량 (픽셀 단위, 양수: 오른쪽)
    ///   - deltaY: Y축 이동량 (픽셀 단위, 양수: 아래)
    /// - Note: UDP로 전송되며 내부적으로 배치 처리됩니다.
    public var sendMouseMove: @Sendable (Float, Float) async -> Void

    /// 마우스 클릭 이벤트를 전송합니다.
    ///
    /// - Parameters:
    ///   - button: 클릭할 버튼 (`.left`, `.right`, `.middle`)
    ///   - action: 클릭 동작 (`.click`, `.double`, `.down`, `.up`)
    public var sendMouseClick: @Sendable (MouseClick.Button, MouseClick.Action) async -> Void

    /// 스크롤 이벤트를 전송합니다.
    ///
    /// - Parameters:
    ///   - deltaX: 수평 스크롤량 (양수: 오른쪽)
    ///   - deltaY: 수직 스크롤량 (양수: 아래)
    ///   - isInertia: 관성 스크롤 여부 (관성 스크롤은 즉시 전송)
    public var sendScroll: @Sendable (Float, Float, Bool) async -> Void

    /// 핀치 제스처 이벤트를 전송합니다.
    ///
    /// - Parameters:
    ///   - scale: 핀치 스케일 (1.0 기준, 확대/축소)
    ///   - phase: 제스처 단계 (`.began`, `.changed`, `.ended`)
    public var sendPinch: @Sendable (Float, Pinch.Phase) async -> Void

    /// 자이로스코프 데이터를 전송합니다 (레이저 포인터 모드).
    ///
    /// - Parameter gyroData: 디바이스 회전 데이터
    public var sendGyroData: @Sendable (GyroData) async -> Void

    // MARK: - Keyboard Input

    /// 키보드 이벤트를 전송합니다.
    ///
    /// - Parameters:
    ///   - keyCode: macOS 가상 키 코드
    ///   - action: 키 동작 (`.down`, `.up`)
    ///   - modifiers: 수정자 키 비트마스크 (Shift, Control, Option, Command)
    public var sendKeyEvent: @Sendable (UInt32, KeyEvent.Action, UInt32) async -> Void

    /// 키보드 조합을 전송합니다.
    ///
    /// 여러 키를 동시에 누른 것처럼 처리됩니다.
    ///
    /// - Parameters:
    ///   - keyCodes: 동시에 누를 키 코드 배열
    ///   - modifiers: 수정자 키 비트마스크
    public var sendKeyCombo: @Sendable ([UInt32], UInt32) async -> Void

    // MARK: - Media Control

    /// 미디어 컨트롤 명령을 전송합니다.
    ///
    /// - Parameters:
    ///   - command: 미디어 명령 (재생, 일시정지, 다음/이전 트랙 등)
    ///   - volume: 볼륨 레벨 (0.0 ~ 1.0, 볼륨 관련 명령에서만 사용)
    public var sendMediaControl: @Sendable (MediaControl.Command, Float) async -> Void

    // MARK: - Window Management

    /// 윈도우 스냅 명령을 전송합니다.
    ///
    /// - Parameter position: 윈도우 배치 위치 (좌측 절반, 우측 절반, 최대화 등)
    public var sendWindowSnap: @Sendable (WindowSnap.Position) async -> Void

    // MARK: - App Control

    /// Mac에서 실행 중인 앱 목록을 요청합니다.
    ///
    /// 응답은 `ConnectionEvent.packet(.appList(_))` 이벤트로 수신됩니다.
    public var requestAppList: @Sendable () async -> Void

    /// 특정 앱으로 포커스를 전환합니다.
    ///
    /// - Parameters:
    ///   - bundleID: 앱의 번들 식별자 (예: "com.apple.Safari")
    ///   - pid: 프로세스 ID
    public var sendAppFocus: @Sendable (String, UInt32) async -> Void

    // MARK: - Voice & Siri

    /// Siri 명령을 전송합니다.
    ///
    /// - Parameters:
    ///   - action: Siri 동작 (활성화, 텍스트 전송)
    ///   - text: 전송할 텍스트 (텍스트 전송 시)
    public var sendSiriCommand: @Sendable (SiriCommand.Action, String) async -> Void

    /// 음성 인식 텍스트를 전송합니다.
    ///
    /// - Parameters:
    ///   - text: 인식된 텍스트
    ///   - isFinal: 최종 인식 결과 여부 (false이면 중간 결과)
    public var sendVoiceText: @Sendable (String, Bool) async -> Void

    // MARK: - System Commands

    /// URL을 Mac에서 열도록 요청합니다.
    ///
    /// - Parameter url: 열 URL 문자열
    public var sendOpenURL: @Sendable (String) async -> Void

    /// 시스템 명령을 전송합니다.
    ///
    /// - Parameter command: 시스템 명령 (잠자기, 화면 잠금, 종료 등)
    /// - Warning: 일부 명령(재시작, 종료)은 즉시 시스템에 적용됩니다.
    public var sendSystemCommand: @Sendable (SystemCommand.Command) async -> Void

    /// 숏폼 영상 컨트롤 명령을 전송합니다.
    ///
    /// - Parameters:
    ///   - platform: 플랫폼 (YouTube Shorts, TikTok, Instagram Reels)
    ///   - action: 컨트롤 동작 (다음, 이전, 좋아요 등)
    public var sendShortsCommand: @Sendable (ShortsCommand.Platform, ShortsCommand.Action) async -> Void

    // MARK: - Pairing

    /// 페어링 PIN 코드 응답을 전송합니다.
    ///
    /// - Parameter pinCode: 사용자가 입력한 4자리 PIN 코드
    public var sendPairingResponse: @Sendable (String) async -> Void
}

// MARK: - Discovery Events

/// Bonjour 디바이스 탐색 중 발생하는 이벤트.
///
/// `startDiscovery()` 호출 후 AsyncStream을 통해 수신됩니다.
public enum DiscoveryEvent: Equatable, Sendable {
    /// 새로운 Mac이 네트워크에서 발견됨
    case deviceFound(DiscoveredDevice)

    /// 이전에 발견된 Mac이 네트워크에서 사라짐
    /// - Parameter id: 사라진 디바이스의 ID
    case deviceLost(String)

    /// 탐색 중 오류 발생
    /// - Parameter message: 오류 메시지
    case error(String)
}

/// Bonjour를 통해 발견된 Mac 디바이스 정보.
///
/// ## 예제
/// ```swift
/// let device = DiscoveredDevice(
///     id: "mac-001",
///     name: "MacBook Pro",
///     host: "192.168.1.100",
///     port: 12345
/// )
/// try await connectionClient.connect(device.host, device.port)
/// ```
public struct DiscoveredDevice: Equatable, Identifiable, Sendable {
    /// 디바이스 고유 식별자 (Bonjour TXT 레코드의 deviceID)
    public let id: String

    /// 디바이스 표시 이름 (예: "MacBook Pro")
    public let name: String

    /// IP 주소 또는 호스트명
    public let host: String

    /// TCP 연결 포트 번호
    public let port: UInt16

    /// 새로운 DiscoveredDevice 인스턴스를 생성합니다.
    public init(id: String, name: String, host: String, port: UInt16) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
    }
}

// MARK: - Connection Events

/// Mac 연결 상태 변화 이벤트.
///
/// `connect()` 호출 후 AsyncStream을 통해 수신됩니다.
public enum ConnectionEvent: Equatable, Sendable {
    /// Mac에 성공적으로 연결됨
    /// - Parameter serverName: 연결된 Mac의 이름
    case connected(serverName: String)

    /// 연결이 해제됨
    /// - Parameter error: 오류로 인한 해제 시 오류 메시지, 정상 해제 시 nil
    case disconnected(error: String?)

    /// Mac으로부터 패킷 수신
    /// - Parameter packet: 수신된 패킷 이벤트
    case packet(PacketEvent)

    /// 연결 중 오류 발생
    /// - Parameter message: 오류 메시지
    case error(String)

    /// Mac에서 페어링 요청 (PIN 입력 필요)
    /// - Parameter serverName: 페어링 요청한 Mac 이름
    case pairingRequired(serverName: String)

    /// 페어링 결과 수신
    /// - Parameters:
    ///   - success: 페어링 성공 여부
    ///   - message: 결과 메시지
    case pairingResult(success: Bool, message: String)
}

/// Mac으로부터 수신한 패킷 이벤트.
public enum PacketEvent: Equatable, Sendable {
    /// 실행 중인 앱 목록 수신
    /// - Parameter apps: 앱 정보 배열
    case appList([AppInfo])

    /// 현재 재생 중인 미디어 정보 수신
    /// - Parameter info: Now Playing 정보
    case nowPlayingInfo(NowPlayingInfo)

    /// 오류 패킷 수신
    /// - Parameter message: 오류 메시지
    case error(String)
}

// MARK: - Dependency Key

extension ConnectionClient: DependencyKey {
    public static var liveValue: ConnectionClient {
        let actor = ConnectionActor()

        return ConnectionClient(
            startDiscovery: { await actor.startDiscovery() },
            stopDiscovery: { await actor.stopDiscovery() },
            connect: { host, port in try await actor.connect(host: host, port: port) },
            disconnect: { await actor.disconnect() },
            sendMouseMove: { dx, dy in await actor.sendMouseMove(deltaX: dx, deltaY: dy) },
            sendMouseClick: { button, action in await actor.sendMouseClick(button: button, action: action) },
            sendScroll: { dx, dy, inertia in await actor.sendScroll(deltaX: dx, deltaY: dy, isInertia: inertia) },
            sendPinch: { scale, phase in await actor.sendPinch(scale: scale, phase: phase) },
            sendGyroData: { gyroData in await actor.sendGyroData(gyroData) },
            sendKeyEvent: { code, action, mods in await actor.sendKeyEvent(keyCode: code, action: action, modifiers: mods) },
            sendKeyCombo: { codes, mods in await actor.sendKeyCombo(keyCodes: codes, modifiers: mods) },
            sendMediaControl: { cmd, vol in await actor.sendMediaControl(command: cmd, volume: vol) },
            sendWindowSnap: { pos in await actor.sendWindowSnap(position: pos) },
            requestAppList: { await actor.requestAppList() },
            sendAppFocus: { bundleID, pid in await actor.sendAppFocus(bundleID: bundleID, pid: pid) },
            sendSiriCommand: { action, text in await actor.sendSiriCommand(action: action, text: text) },
            sendVoiceText: { text, isFinal in await actor.sendVoiceText(text: text, isFinal: isFinal) },
            sendOpenURL: { url in await actor.sendOpenURL(url: url) },
            sendSystemCommand: { command in await actor.sendSystemCommand(command: command) },
            sendShortsCommand: { platform, action in await actor.sendShortsCommand(platform: platform, action: action) },
            sendPairingResponse: { pin in await actor.sendPairingResponse(pinCode: pin) }
        )
    }

    public static var testValue: ConnectionClient {
        ConnectionClient(
            startDiscovery: { .finished },
            stopDiscovery: {},
            connect: { _, _ in .finished },
            disconnect: {},
            sendMouseMove: { _, _ in },
            sendMouseClick: { _, _ in },
            sendScroll: { _, _, _ in },
            sendPinch: { _, _ in },
            sendGyroData: { _ in },
            sendKeyEvent: { _, _, _ in },
            sendKeyCombo: { _, _ in },
            sendMediaControl: { _, _ in },
            sendWindowSnap: { _ in },
            requestAppList: {},
            sendAppFocus: { _, _ in },
            sendSiriCommand: { _, _ in },
            sendVoiceText: { _, _ in },
            sendOpenURL: { _ in },
            sendSystemCommand: { _ in },
            sendShortsCommand: { _, _ in },
            sendPairingResponse: { _ in }
        )
    }
}

public extension DependencyValues {
    var connectionClient: ConnectionClient {
        get { self[ConnectionClient.self] }
        set { self[ConnectionClient.self] = newValue }
    }
}

// MARK: - Connection Actor

private actor ConnectionActor: SnapClientDelegate, BonjourBrowserDelegate {
    private var client: SnapClient?
    private var browser: BonjourBrowser?

    private var discoveryContinuation: AsyncStream<DiscoveryEvent>.Continuation?
    private var connectionContinuation: AsyncStream<ConnectionEvent>.Continuation?

    // MARK: - Packet Batcher

    private var packetBatcher: PacketBatcher?

    private func setupBatcher() {
        Task { @MainActor in
            let batcher = PacketBatcher()
            batcher.start(
                onMouseMoveFlush: { [weak self] dx, dy in
                    guard let self else { return }
                    Task {
                        await self.flushMouseMove(deltaX: dx, deltaY: dy)
                    }
                },
                onScrollFlush: { [weak self] dx, dy in
                    guard let self else { return }
                    Task {
                        await self.flushScroll(deltaX: dx, deltaY: dy)
                    }
                }
            )
            await self.setBatcher(batcher)
        }
    }

    private func setBatcher(_ batcher: PacketBatcher) {
        self.packetBatcher = batcher
    }

    private func stopBatcher() {
        Task { @MainActor in
            await self.packetBatcher?.stop()
            await self.clearBatcher()
        }
    }

    private func clearBatcher() {
        self.packetBatcher = nil
    }

    private func flushMouseMove(deltaX: Float, deltaY: Float) {
        client?.sendMouseMove(deltaX: deltaX, deltaY: deltaY)
    }

    private func flushScroll(deltaX: Float, deltaY: Float) {
        client?.sendScroll(deltaX: deltaX, deltaY: deltaY, isInertia: false)
    }

    // MARK: - Discovery

    func startDiscovery() -> AsyncStream<DiscoveryEvent> {
        AsyncStream { continuation in
            self.discoveryContinuation = continuation

            self.browser = BonjourBrowser()
            self.browser?.delegate = self
            self.browser?.startSearching()

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.stopDiscovery()
                }
            }
        }
    }

    func stopDiscovery() {
        browser?.stopSearching()
        browser = nil
        discoveryContinuation?.finish()
        discoveryContinuation = nil
    }

    // MARK: - Connection

    func connect(host: String, port: UInt16) throws -> AsyncStream<ConnectionEvent> {
        // 배칭 시작
        setupBatcher()

        return AsyncStream { continuation in
            self.connectionContinuation = continuation

            self.client = SnapClient()
            self.client?.delegate = self
            self.client?.connect(to: host, port: port)

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.disconnect()
                }
            }
        }
    }

    func disconnect() {
        // 배칭 중지
        stopBatcher()

        client?.disconnect()
        client = nil
        connectionContinuation?.finish()
        connectionContinuation = nil
    }

    // MARK: - Send Methods

    func sendMouseMove(deltaX: Float, deltaY: Float) {
        // 배치 처리 사용
        Task { @MainActor in
            await self.packetBatcher?.addMouseMove(deltaX: deltaX, deltaY: deltaY)
        }
    }

    func sendMouseClick(button: MouseClick.Button, action: MouseClick.Action) {
        // 클릭은 즉시 전송 (배치 대상 아님)
        client?.sendMouseClick(button: button, action: action)
    }

    func sendScroll(deltaX: Float, deltaY: Float, isInertia: Bool) {
        if isInertia {
            // 관성 스크롤은 즉시 전송
            client?.sendScroll(deltaX: deltaX, deltaY: deltaY, isInertia: isInertia)
        } else {
            // 일반 스크롤은 배치 처리
            Task { @MainActor in
                await self.packetBatcher?.addScroll(deltaX: deltaX, deltaY: deltaY)
            }
        }
    }

    func sendPinch(scale: Float, phase: Pinch.Phase) {
        client?.sendPinch(scale: scale, phase: phase)
    }

    func sendGyroData(_ gyroData: GyroData) {
        client?.sendGyroData(gyroData)
    }

    func sendKeyEvent(keyCode: UInt32, action: KeyEvent.Action, modifiers: UInt32) {
        client?.sendKeyEvent(keyCode: keyCode, action: action, modifiers: modifiers)
    }

    func sendKeyCombo(keyCodes: [UInt32], modifiers: UInt32) {
        client?.sendKeyCombo(keyCodes: keyCodes, modifiers: modifiers)
    }

    func sendMediaControl(command: MediaControl.Command, volume: Float) {
        client?.sendMediaControl(command: command, volume: volume)
    }

    func sendWindowSnap(position: WindowSnap.Position) {
        client?.sendWindowSnap(position: position)
    }

    func requestAppList() {
        client?.requestAppList()
    }

    func sendAppFocus(bundleID: String, pid: UInt32) {
        client?.sendAppFocus(bundleID: bundleID, pid: pid)
    }

    func sendSiriCommand(action: SiriCommand.Action, text: String) {
        client?.sendSiriCommand(action: action, text: text)
    }

    func sendVoiceText(text: String, isFinal: Bool) {
        client?.sendVoiceText(text: text, isFinal: isFinal)
    }

    func sendOpenURL(url: String) {
        client?.sendOpenURL(url: url)
    }

    func sendSystemCommand(command: SystemCommand.Command) {
        client?.sendSystemCommand(command: command)
    }

    func sendShortsCommand(platform: ShortsCommand.Platform, action: ShortsCommand.Action) {
        client?.sendShortsCommand(platform: platform, action: action)
    }

    func sendPairingResponse(pinCode: String) {
        client?.sendPairingResponse(pinCode: pinCode)
    }

    // MARK: - SnapClientDelegate

    nonisolated func clientDidConnect(_ client: SnapClient) {
        Task {
            await self.handleConnect(serverName: client.serverDeviceName ?? "Mac")
        }
    }

    private func handleConnect(serverName: String) {
        connectionContinuation?.yield(.connected(serverName: serverName))
    }

    nonisolated func clientDidDisconnect(_ client: SnapClient, error: Error?) {
        Task {
            await self.handleDisconnect(error: error)
        }
    }

    private func handleDisconnect(error: Error?) {
        connectionContinuation?.yield(.disconnected(error: error?.localizedDescription))
        connectionContinuation?.finish()
        connectionContinuation = nil
        self.client = nil
    }

    nonisolated func client(_ client: SnapClient, didReceive packet: DecodedPacket) {
        Task {
            await self.handlePacket(packet)
        }
    }

    private func handlePacket(_ packet: DecodedPacket) {
        switch packet {
        case .appListResponse(let response, _):
            connectionContinuation?.yield(.packet(.appList(response.apps)))
        case .nowPlayingInfo(let info, _):
            connectionContinuation?.yield(.packet(.nowPlayingInfo(info)))
        case .error(let snapError, _):
            connectionContinuation?.yield(.packet(.error(snapError.message)))
        default:
            break
        }
    }

    nonisolated func client(_ client: SnapClient, didFailWithError error: Error) {
        Task {
            await self.handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        connectionContinuation?.yield(.error(error.localizedDescription))
    }

    nonisolated func client(_ client: SnapClient, didReceivePairingChallenge challenge: PairingChallenge) {
        Task {
            await self.handlePairingChallenge(challenge)
        }
    }

    private func handlePairingChallenge(_ challenge: PairingChallenge) {
        connectionContinuation?.yield(.pairingRequired(serverName: challenge.deviceName))
    }

    nonisolated func client(_ client: SnapClient, didReceivePairingResult result: PairingResult) {
        Task {
            await self.handlePairingResult(result)
        }
    }

    private func handlePairingResult(_ result: PairingResult) {
        connectionContinuation?.yield(.pairingResult(success: result.isSuccess, message: result.message))
    }

    // MARK: - BonjourBrowserDelegate

    nonisolated func bonjourBrowser(_ browser: BonjourBrowser, didFind service: DiscoveredService) {
        Task {
            await self.handleServiceFound(service)
        }
    }

    private func handleServiceFound(_ service: DiscoveredService) {
        let deviceID = service.txtRecord["deviceID"] ?? service.name
        let device = DiscoveredDevice(
            id: deviceID,
            name: service.name,
            host: service.host,
            port: service.port
        )
        discoveryContinuation?.yield(.deviceFound(device))
    }

    nonisolated func bonjourBrowser(_ browser: BonjourBrowser, didRemove service: DiscoveredService) {
        Task {
            await self.handleServiceLost(service.name)
        }
    }

    private func handleServiceLost(_ serviceName: String) {
        discoveryContinuation?.yield(.deviceLost(serviceName))
    }

    nonisolated func bonjourBrowser(_ browser: BonjourBrowser, didFailWithError error: Error) {
        Task {
            await self.handleBrowseError(error)
        }
    }

    private func handleBrowseError(_ error: Error) {
        discoveryContinuation?.yield(.error(error.localizedDescription))
    }
}
