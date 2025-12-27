# TDD Verify

커밋 전 전체 검증을 수행합니다.

## 실행 단계

1. 빌드 검증
   ```bash
   tuist build App
   tuist build MacReceiver
   ```

2. 테스트 실행
   ```bash
   tuist test
   ```

3. 린트 검사 (설정된 경우)
   ```bash
   swiftlint lint --strict
   ```

4. 결과 출력
   ```
   🔍 커밋 전 검증

   📦 빌드
   ✅ App: 성공
   ✅ MacReceiver: 성공

   🧪 테스트
   ✅ 전체 통과 (N개)

   🔎 린트
   ✅ 경고 없음

   ✅ 커밋 준비 완료!
   ```

5. 실패 시 수정 안내

## 주의사항
- 모든 검증 통과 후에만 커밋
- 경고도 가능하면 해결
