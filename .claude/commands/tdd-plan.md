# TDD Plan

기능에 대한 테스트 계획을 수립하고 plan.md 파일을 생성합니다.

## 입력
$ARGUMENTS: 구현할 기능 설명

## 실행 단계

1. 기능 분석
   - 요구사항 파악
   - 필요한 컴포넌트/모듈 식별
   - 의존성 확인

2. 테스트 목록 작성
   - 단위 테스트 (Unit Tests)
   - 통합 테스트 (Integration Tests)
   - UI 테스트 (필요시)

3. plan.md 생성
   ```markdown
   # TDD Plan: [기능명]

   ## 개요
   [기능 설명]

   ## 테스트 목록

   ### Unit Tests
   - [ ] test_기능1_정상케이스
   - [ ] test_기능1_에러케이스
   - [ ] test_기능2_정상케이스

   ### Integration Tests
   - [ ] test_통합_시나리오1

   ## 구현 순서
   1. ...
   2. ...
   ```

4. 첫 번째 테스트 안내

## 주의사항
- Kent Beck TDD 원칙 준수
- 작은 단위로 테스트 분리
- 명확한 테스트 이름 사용 (shouldXxxWhenYyy 형식)
