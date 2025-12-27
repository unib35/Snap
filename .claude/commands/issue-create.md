# Issue Create

GitHub 이슈를 생성합니다.

## 입력
$ARGUMENTS: 이슈 제목 및 설명

## 실행 단계

1. 이슈 정보 수집
   - 타입 결정 (feat, fix, setting 등)
   - 우선순위 결정 (P0, P1, P2)
   - 관련 Phase 확인
   - 관련 Area 확인

2. 이슈 템플릿 적용
   ```markdown
   ## ✅ 이슈 개요

   [간략한 설명]

   ---

   ## 📝 작업 상세 내용

   - [ ] 작업 1
   - [ ] 작업 2
   - [ ] 작업 3
   ```

3. 이슈 생성
   ```bash
   gh issue create \
     --title "[Type]: 제목" \
     --body "본문" \
     --label "label1,label2" \
     --milestone "Phase N: Name"
   ```

4. 결과 출력
   - 생성된 이슈 URL
   - 할당된 라벨
   - 할당된 마일스톤

## 라벨 가이드
- 타입: `feat`, `fix`, `setting`, `design`, `docs`
- 우선순위: `P0`, `P1`, `P2`
- Phase: `phase: foundation`, `phase: essentials` 등
- Area: `area: trackpad`, `area: keyboard` 등

## 주의사항
- docs/git/issue-labels.md 참고
- 마일스톤 할당 권장
