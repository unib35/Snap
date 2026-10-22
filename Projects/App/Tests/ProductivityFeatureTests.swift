import Shared
import Testing
@testable import App

@Suite("창 정렬 테스트")
struct WindowSnapOptionTests {
    @Test("Mac이 지원하는 모든 창 정렬 위치를 버튼으로 제공")
    func displayOrderCoversAllPositions() {
        let order = WindowSnap.Position.displayOrder
        #expect(order.count == WindowSnap.Position.allCases.count)
        #expect(Set(order) == Set(WindowSnap.Position.allCases))
    }

    @Test("위치마다 서로 다른 이름을 사용")
    func labelsAreUnique() {
        let labels = WindowSnap.Position.displayOrder.map(\.label)
        #expect(Set(labels).count == labels.count)
    }
}
