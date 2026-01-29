import AppKit
import Foundation
import Shared

/// 숏폼 리모컨 컨트롤러
/// 플랫폼별 키보드 단축키를 사용하여 숏폼 영상을 제어합니다.
@MainActor
public final class ShortsController {
    public static let shared = ShortsController()

    private init() {}

    // MARK: - Key Codes

    private enum KeyCode {
        static let upArrow: CGKeyCode = 126
        static let downArrow: CGKeyCode = 125
        static let leftArrow: CGKeyCode = 123
        static let rightArrow: CGKeyCode = 124
        static let space: CGKeyCode = 49
        static let mKey: CGKeyCode = 46
        static let lKey: CGKeyCode = 37       // YouTube like
        static let cKey: CGKeyCode = 8        // Comment
        static let sKey: CGKeyCode = 1        // Share
        static let jKey: CGKeyCode = 38       // YouTube: 10초 뒤로
        static let kKey: CGKeyCode = 40       // YouTube: 재생/일시정지
        static let enterKey: CGKeyCode = 36   // Instagram: 좋아요 (댓글창에서)
    }

    // MARK: - Public Methods

    /// 숏폼 명령 실행
    public func execute(command: ShortsCommand) {
        switch command.action {
        case .nextVideo:
            nextVideo(platform: command.platform)
        case .previousVideo:
            previousVideo(platform: command.platform)
        case .playPause:
            playPause(platform: command.platform)
        case .mute:
            mute(platform: command.platform)
        case .like:
            like(platform: command.platform)
        case .comment:
            comment(platform: command.platform)
        case .share:
            share(platform: command.platform)
        case .seekForward:
            seekForward(platform: command.platform)
        case .seekBackward:
            seekBackward(platform: command.platform)
        }
    }

    // MARK: - Navigation

    /// 다음 영상
    private func nextVideo(platform: ShortsCommand.Platform) {
        // 모든 플랫폼에서 아래 화살표로 다음 영상
        sendKeyEvent(keyCode: KeyCode.downArrow)
    }

    /// 이전 영상
    private func previousVideo(platform: ShortsCommand.Platform) {
        // 모든 플랫폼에서 위 화살표로 이전 영상
        sendKeyEvent(keyCode: KeyCode.upArrow)
    }

    // MARK: - Playback

    /// 재생/일시정지
    private func playPause(platform: ShortsCommand.Platform) {
        switch platform {
        case .youtube:
            // YouTube: K 또는 Space
            sendKeyEvent(keyCode: KeyCode.kKey)
        case .instagram, .tiktok:
            // Instagram/TikTok: Space
            sendKeyEvent(keyCode: KeyCode.space)
        }
    }

    /// 음소거
    private func mute(platform: ShortsCommand.Platform) {
        // 모든 플랫폼에서 M 키로 음소거
        sendKeyEvent(keyCode: KeyCode.mKey)
    }

    /// 앞으로 탐색
    private func seekForward(platform: ShortsCommand.Platform) {
        switch platform {
        case .youtube:
            // YouTube: L (10초 앞으로) 또는 오른쪽 화살표 (5초)
            sendKeyEvent(keyCode: KeyCode.rightArrow)
        case .instagram, .tiktok:
            // Instagram/TikTok: 오른쪽 화살표
            sendKeyEvent(keyCode: KeyCode.rightArrow)
        }
    }

    /// 뒤로 탐색
    private func seekBackward(platform: ShortsCommand.Platform) {
        switch platform {
        case .youtube:
            // YouTube: J (10초 뒤로) 또는 왼쪽 화살표 (5초)
            sendKeyEvent(keyCode: KeyCode.leftArrow)
        case .instagram, .tiktok:
            // Instagram/TikTok: 왼쪽 화살표
            sendKeyEvent(keyCode: KeyCode.leftArrow)
        }
    }

    // MARK: - Interactions

    /// 좋아요
    private func like(platform: ShortsCommand.Platform) {
        switch platform {
        case .youtube:
            // YouTube Shorts: L 키
            sendKeyEvent(keyCode: KeyCode.lKey)
        case .instagram:
            // Instagram: 더블 클릭으로 좋아요 (키보드로는 어려움)
            // 대안: L 키 시도
            sendKeyEvent(keyCode: KeyCode.lKey)
        case .tiktok:
            // TikTok: L 키
            sendKeyEvent(keyCode: KeyCode.lKey)
        }
    }

    /// 댓글
    private func comment(platform: ShortsCommand.Platform) {
        switch platform {
        case .youtube:
            // YouTube: C 키 (댓글 섹션 포커스)
            sendKeyEvent(keyCode: KeyCode.cKey)
        case .instagram, .tiktok:
            // 다른 플랫폼도 C 시도
            sendKeyEvent(keyCode: KeyCode.cKey)
        }
    }

    /// 공유
    private func share(platform: ShortsCommand.Platform) {
        switch platform {
        case .youtube:
            // YouTube: S 키 (공유 다이얼로그)
            sendKeyEvent(keyCode: KeyCode.sKey)
        case .instagram, .tiktok:
            // 다른 플랫폼도 S 시도
            sendKeyEvent(keyCode: KeyCode.sKey)
        }
    }

    // MARK: - Key Event Helpers

    private func sendKeyEvent(keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDownEvent.flags = modifiers
        keyUpEvent.flags = modifiers

        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
}
