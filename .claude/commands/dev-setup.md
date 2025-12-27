# Dev Setup

개발 환경을 설정하거나 진단합니다.

## 입력 (선택)
$ARGUMENTS: `reset` - 클린 재설치

## 실행 단계

### 일반 설정

1. Tuist 버전 확인
   ```bash
   tuist version
   ```

2. 의존성 설치
   ```bash
   tuist install
   ```

3. 프로젝트 생성
   ```bash
   tuist generate
   ```

4. 빌드 테스트
   ```bash
   tuist build App
   tuist build MacReceiver
   ```

### Reset 모드 (`/dev-setup reset`)

1. 기존 파일 정리
   ```bash
   rm -rf Derived/
   rm -rf Tuist/Dependencies/
   rm -rf ~/Library/Developer/Xcode/DerivedData/Snap-*
   ```

2. 캐시 정리
   ```bash
   tuist clean
   ```

3. 재설치
   ```bash
   tuist install
   tuist generate
   ```

## 결과 출력
```
🔧 개발 환경 설정

✅ Tuist 4.x.x
✅ 의존성 설치 완료
✅ 프로젝트 생성 완료
✅ 빌드 성공

🎉 개발 준비 완료!
Xcode에서 Snap.xcworkspace를 열어주세요.
```

## 주의사항
- reset은 시간이 오래 걸릴 수 있음
- Xcode가 열려있으면 닫고 실행
