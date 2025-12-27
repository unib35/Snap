# Feature New

새 기능을 위한 브랜치와 이슈를 생성합니다.

## 입력
$ARGUMENTS: 기능 이름 (kebab-case)

## 실행 단계

1. develop 브랜치 최신화
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. Feature 브랜치 생성
   ```bash
   git checkout -b feat/{feature-name}
   ```

3. GitHub 이슈 생성 (선택)
   - `/issue-create` 실행 제안

4. 결과 출력
   ```
   🚀 새 기능 시작

   📁 브랜치: feat/{feature-name}

   다음 단계:
   1. /tdd-plan {기능 설명}  - 테스트 계획 수립
   2. /tdd-go               - TDD 개발 시작
   ```

## TCA Feature 구조 가이드

iOS 앱에서 새 기능 추가 시 권장 구조:

```
Projects/App/Sources/Features/{FeatureName}/
├── {FeatureName}Feature.swift    # Reducer
├── {FeatureName}View.swift       # SwiftUI View
└── Components/                   # 하위 컴포넌트 (필요시)
```

## 주의사항
- develop에서 분기
- 브랜치명은 kebab-case
- 마이크로 브랜치 전략 준수
