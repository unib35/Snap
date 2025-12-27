# PR Create

Pull Request를 생성합니다.

## 입력 (선택)
$ARGUMENTS: 대상 브랜치 (기본: develop)

## 실행 단계

1. 현재 상태 확인
   ```bash
   git status
   git log develop..HEAD --oneline
   git diff develop...HEAD --stat
   ```

2. 검증 수행
   ```bash
   tuist build App
   tuist build MacReceiver
   tuist test
   ```

3. PR 본문 생성 (템플릿 적용)
   ```markdown
   ## 🔮 작업 요약

   [핵심 목표 요약]

   ## 🖥️ 상세 작업 내용

   - [x] 작업 1
   - [x] 작업 2

   ## 📸 스크린샷

   | 변경 전 | 변경 후 |
   |---------|---------|
   | - | - |

   ## 📌 이슈 및 특이사항

   - **이슈**:
   - **특이사항**:

   ## 🚀 다음에 할 일

   -
   ```

4. PR 생성
   ```bash
   gh pr create \
     --base develop \
     --title "[Type]: 제목" \
     --body "본문"
   ```

5. 결과 출력
   - PR URL
   - 변경 파일 수
   - 리뷰어 할당 안내

## 주의사항
- develop 브랜치에서 직접 작업 금지
- 빌드/테스트 통과 필수
- 스크린샷은 UI 변경 시에만
