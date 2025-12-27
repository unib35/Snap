# TDD Go

plan.md에서 다음 미완료 테스트를 찾아 Red → Green 사이클을 수행합니다.

## 실행 단계

1. plan.md 확인
   - 다음 `- [ ]` 항목 찾기
   - 해당 테스트 요구사항 파악

2. Red Phase (실패하는 테스트 작성)
   - 테스트 파일 생성/수정
   - Swift Testing 프레임워크 사용
   - 테스트 실행하여 실패 확인

3. Green Phase (최소 구현)
   - 테스트를 통과하는 최소한의 코드 작성
   - 테스트 실행하여 통과 확인

4. plan.md 업데이트
   - `- [ ]` → `- [x]` 변경

5. 다음 테스트 안내

## 테스트 작성 규칙

```swift
import Testing
@testable import App

@Test
func shouldReturnEmptyArrayWhenNoDevices() async throws {
    // Given
    let sut = DiscoveryClient()

    // When
    let devices = await sut.discover()

    // Then
    #expect(devices.isEmpty)
}
```

## 주의사항
- 한 번에 하나의 테스트만 구현
- 최소한의 코드만 작성 (YAGNI)
- 테스트 통과 후 다음 단계로
