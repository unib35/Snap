# TDD Test

테스트를 실행하고 결과를 분석합니다.

## 입력 (선택)
$ARGUMENTS: 특정 테스트 타겟 또는 파일 (없으면 전체)

## 실행 단계

1. 테스트 실행
   ```bash
   # 전체 테스트
   tuist test

   # 특정 타겟
   tuist test AppTests
   tuist test MacReceiverTests

   # 특정 테스트
   tuist test -- -only-testing:AppTests/TestClassName/testMethodName
   ```

2. 결과 분석
   - 성공/실패 테스트 수
   - 실패한 테스트 상세 정보
   - 코드 커버리지 (가능한 경우)

3. 결과 출력
   ```
   🧪 테스트 결과

   ✅ 통과: N개
   ❌ 실패: M개

   [실패 테스트 상세]
   - TestName: 에러 메시지
   ```

4. 실패 시 수정 제안

## 주의사항
- 실패한 테스트는 즉시 수정
- Green 상태 유지 필수
