# Dev Check

프로젝트 상태를 한눈에 확인합니다.

## 실행 단계

1. Git 상태 확인
   ```bash
   git status
   git branch --show-current
   ```

2. Tuist 상태 확인
   ```bash
   tuist version
   ls -la Derived/  # 생성된 프로젝트 확인
   ```

3. 의존성 상태 확인
   ```bash
   ls -la Tuist/Dependencies/  # 설치된 의존성
   ```

4. 빌드 상태 확인
   ```bash
   tuist build App -- -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
   tuist build MacReceiver -quiet
   ```

5. 결과 출력
   ```
   🔍 프로젝트 상태

   📁 Git
   브랜치: develop
   상태: clean / N개 변경

   🛠️ Tuist
   버전: 4.x.x
   프로젝트: ✅ 생성됨

   📦 의존성
   TCA: ✅
   SwiftProtobuf: ✅

   🏗️ 빌드
   App (iOS): ✅
   MacReceiver (macOS): ✅
   ```

## 주의사항
- 문제 발견 시 `/dev-setup` 실행 안내
