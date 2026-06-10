# kbo-live

KBO 경기를 Apple 플랫폼에서 실시간으로 보기 위한 앱/백엔드 스파이크 저장소입니다.

현재 범위:
- iPhone 앱 설계
- Widget / Live Activity 설계
- macOS Menu Bar 앱 설계
- KBO 데이터 수집용 backend spike
- shared Swift DTO / domain scaffold

## 디렉터리

```text
PROJECT_CONTEXT/   # 제품/아키텍처/구현 계획 문서
backend-spike/    # KBO source 검증용 Fastify + TypeScript spike
Packages/         # Swift shared package scaffold
```

## 현재 상태

문서화 완료:
- 앱 초기 계획
- Xcode/SwiftUI 구조
- backend spike 계획/결과
- Swift app bootstrap 파일 구조
- shared DTO 초안

구현 완료:
- `backend-spike/` 최소 실행 가능 scaffold
- `/health`, `/games/today`, `/games/:gameId`, `/debug/source/today`
- polling / dump / fixture 저장 흐름
- `Packages/KboLiveCore` 최소 DTO/domain/mapper/test scaffold
- widget / live activity / menu bar projection 모델 및 mapper 초안

## 빠른 시작

### backend spike
```bash
cd backend-spike
npm install
npm run dev
```

### Swift package
이 Linux 호스트에는 Swift toolchain이 없어서 검증은 Mac/Xcode 환경에서 진행해야 합니다.

예상 검증 명령:
```bash
cd Packages/KboLiveCore
swift test
```

## 참고 문서
- `PROJECT_CONTEXT/kbo-live-app-initial-plan.md`
- `PROJECT_CONTEXT/xcode-project-structure.md`
- `PROJECT_CONTEXT/swiftui-component-structure.md`
- `PROJECT_CONTEXT/backend-spike-plan.md`
- `PROJECT_CONTEXT/backend-spike-results.md`
- `PROJECT_CONTEXT/swift-app-bootstrap-files.md`
- `PROJECT_CONTEXT/shared-dto-draft.md`
