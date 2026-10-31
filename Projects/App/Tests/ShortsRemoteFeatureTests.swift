import ComposableArchitecture
import Shared
import Testing
@testable import App

@MainActor
@Suite("ShortsRemoteFeature 좋아요 테스트")
struct ShortsRemoteLikeTests {
    @Test("좋아요를 누르면 명령을 보내고 확인 표시를 잠시 보여준 뒤 숨김")
    func likeShowsConfirmationBriefly() async {
        let clock = TestClock()
        let sent = LockIsolated<[ShortsCommand.Action]>([])
        let store = TestStore(initialState: ShortsRemoteFeature.State()) {
            ShortsRemoteFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.connectionClient.sendShortsCommand = { _, command in
                sent.withValue { $0.append(command) }
            }
        }

        await store.send(.likeTapped) {
            $0.isShowingLikeConfirmation = true
        }
        await clock.advance(by: ShortsRemoteFeature.likeConfirmationDuration)
        await store.receive(\.likeConfirmationEnded) {
            $0.isShowingLikeConfirmation = false
        }
        #expect(sent.value == [.like])
    }

    @Test("연속으로 누르면 매번 명령을 보내고 마지막 탭 기준으로 확인 표시를 숨김")
    func repeatedLikeRestartsConfirmation() async {
        let clock = TestClock()
        let sent = LockIsolated<[ShortsCommand.Action]>([])
        let store = TestStore(initialState: ShortsRemoteFeature.State()) {
            ShortsRemoteFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.connectionClient.sendShortsCommand = { _, command in
                sent.withValue { $0.append(command) }
            }
        }

        await store.send(.likeTapped) {
            $0.isShowingLikeConfirmation = true
        }
        await clock.advance(by: .milliseconds(500))
        await store.send(.likeTapped)
        await clock.advance(by: .milliseconds(500))
        await clock.advance(by: ShortsRemoteFeature.likeConfirmationDuration)
        await store.receive(\.likeConfirmationEnded) {
            $0.isShowingLikeConfirmation = false
        }
        #expect(sent.value == [.like, .like])
    }
}
