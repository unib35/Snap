import AVFoundation
import Combine
import MediaPlayer
import os.log
import UIKit

/// iOS 물리 볼륨 버튼 이벤트 감지
@MainActor
public final class VolumeButtonHandler: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var currentVolume: Float = 0.5

    // MARK: - Callbacks

    public var onVolumeUp: (() -> Void)?
    public var onVolumeDown: (() -> Void)?

    // MARK: - Private Properties

    private var volumeView: MPVolumeView?
    private var volumeObservation: NSKeyValueObservation?
    private var lastVolume: Float = 0.5
    private var isActive: Bool = false

    // Volume change detection threshold
    private let volumeChangeThreshold: Float = 0.01

    private let logger = Logger(subsystem: "com.snap.app", category: "VolumeButtonHandler")

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// 볼륨 버튼 감지 시작
    public func start() {
        guard !isActive else { return }
        isActive = true

        setupAudioSession()
        setupVolumeView()
        startObservingVolume()
    }

    /// 볼륨 버튼 감지 중지
    public func stop() {
        isActive = false
        volumeObservation?.invalidate()
        volumeObservation = nil
        volumeView?.removeFromSuperview()
        volumeView = nil
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            lastVolume = audioSession.outputVolume
            currentVolume = lastVolume
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func setupVolumeView() {
        // MPVolumeView를 화면 밖에 배치하여 시스템 볼륨 UI 숨기기
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        volumeView.setRouteButtonImage(nil, for: .normal)
        volumeView.showsVolumeSlider = true
        volumeView.alpha = 0.01

        // 현재 윈도우에 추가
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
        }

        self.volumeView = volumeView
    }

    private func startObservingVolume() {
        let audioSession = AVAudioSession.sharedInstance()

        volumeObservation = audioSession.observe(\.outputVolume, options: [.new, .old]) { [weak self] _, change in
            let newVolume = change.newValue ?? 0.5
            let oldVolume = change.oldValue ?? 0.5

            // 볼륨 변경 감지
            let volumeDiff = newVolume - oldVolume

            Task { @MainActor [weak self] in
                guard let self = self, self.isActive else { return }
                guard abs(volumeDiff) > self.volumeChangeThreshold else { return }

                self.currentVolume = newVolume

                if volumeDiff > 0 {
                    self.onVolumeUp?()
                } else {
                    self.onVolumeDown?()
                }

                self.lastVolume = newVolume
            }
        }
    }

    /// 시스템 볼륨을 중간값으로 리셋 (연속 감지를 위해)
    public func resetSystemVolume() {
        // 볼륨이 0 또는 1에 도달하면 더 이상 버튼을 감지할 수 없으므로
        // 중간값으로 리셋하는 옵션 제공
        guard let slider = volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            slider.value = 0.5
            self.lastVolume = 0.5
            self.currentVolume = 0.5
        }
    }
}
