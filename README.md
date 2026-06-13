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
- 현재 프로젝트 구조
- backend spike 계획/결과
- 데이터 소스 조사
- shared DTO 초안
- SwiftUI 컴포넌트 구조

구현 완료:
- `backend-spike/` 최소 실행 가능 scaffold
- `/health`, `/games/today`, `/games/:gameId`, `/debug/source/today`
- polling / dump / fixture 저장 흐름
- `Packages/KboLiveCore` 최소 DTO/domain/mapper/test scaffold
- widget / live activity / menu bar projection 모델 및 mapper 초안
- `Packages/KboLiveDesignSystem` token/theme/primitive scaffold

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

### Xcode project
프로젝트 파일은 `project.yml`에서 생성합니다.

```bash
/private/tmp/XcodeGen/.build/release/xcodegen generate
open KboLiveApp.xcodeproj
```

참고:
- 루트에 `KboLive.xcworkspace`도 같이 두었지만, 현재 샌드박스의 `xcodebuild -workspace` 검증은 통과하지 못했습니다.
- 실제 빌드 검증은 `KboLiveApp.xcodeproj` 기준으로 수행했습니다.

현재 포함 타깃:
- `KboLiveiOS`
- `KboLivemacOS`
- `KboLiveWidgetExtension`

macOS 앱 기본 동작:
- `KBO_LIVE_BASE_URL`을 지정하지 않으면 샘플 경기 데이터로 실행됩니다.
- 실데이터 백엔드에 연결하려면 예: `KBO_LIVE_BASE_URL=http://127.0.0.1:3000`

로컬 검증에 사용한 명령:
```bash
env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme KboLivemacOS -project KboLiveApp.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build

env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme KboLiveiOS -project KboLiveApp.xcodeproj -destination 'generic/platform=iOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build
```

## 참고 문서
- `PROJECT_CONTEXT/README.md`
- `PROJECT_CONTEXT/xcode-project-structure.md`
- `PROJECT_CONTEXT/forward-development-roadmap.md`
- `PROJECT_CONTEXT/backend-spike-results.md`
