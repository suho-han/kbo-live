# kbo-live

KBO 경기를 Apple 플랫폼에서 실시간으로 보기 위한 앱/백엔드 스파이크 저장소입니다.

## TL;DR

맥 프론트(메뉴바 앱)와 packaged backend를 같이 실행:

```bash
xcodebuild -scheme KboLivemacOS -project KboLiveApp.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build
PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

맥 프론트만 실행:

```bash
xcodebuild -scheme KboLivemacOS -project KboLiveApp.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build
launchctl unsetenv KBO_LIVE_BASE_URL
open -n .xcode/DerivedData/Build/Products/Debug/KboLiveApp.app
```

진행 중 경기 UI를 fixture로 바로 확인:

```bash
KBO_USE_TEST_LIVE_GAME=1 FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

백엔드만 실행:

```bash
cd backend-spike
npm install
npm run dev
```

현재 범위:
- macOS Menu Bar 앱 제품화 우선
- macOS packaged backend / Mac-mini 원격 검증
- iPhone 앱 설계
- Widget / Live Activity 설계
- KBO 데이터 수집/정규화/fixture 저장용 backend spike
- shared Swift DTO / domain scaffold

## 디렉터리

```text
PROJECT_CONTEXT/   # 제품/아키텍처/구현 계획 문서
backend-spike/    # KBO source 검증용 Fastify + TypeScript spike
KboLiveApp/       # iOS/macOS/Widget 앱 타깃 소스
Packages/         # Swift shared core/features/design-system packages
scripts/          # 로컬 실행, 패키징, 검증 wrapper
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
- `/health`, `/ready`, `/v1/health`, `/v1/ready`, `/v1/games/today`, `/v1/games/:gameId`
- MVP local 호환용 `/games/today`, `/games/:gameId`, `/debug/source/today`
- 순위/선수 기록 API: `/v1/standings`, `/v1/teams/standings`, `/v1/players/search`, `/v1/players/:playerId/season`
- backend cache, concurrent request dedupe, stale-if-error fallback
- SQLite raw source 기록 및 선수/팀 기록 repository foundation
- polling / dump / fixture 저장 흐름
- `Packages/KboLiveCore` 최소 DTO/domain/mapper/test scaffold
- `Packages/KboLiveFeatures` 오늘 경기/상세 화면 view model 및 feature test scaffold
- widget / live activity / menu bar projection 모델 및 mapper 초안
- `Packages/KboLiveDesignSystem` token/theme/primitive scaffold
- iOS/macOS app target, 설정 화면, 메뉴바 dashboard, 경기 상세 화면
- 팀 로고/워드마크 앱 asset 반영
- macOS 앱 + packaged backend 로컬 실행 스크립트

## 빠른 시작

### macOS 프론트

앱을 빌드한 뒤 packaged backend와 함께 실행합니다.

```bash
xcodebuild -scheme KboLivemacOS -project KboLiveApp.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build
PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

backend를 새로 띄우지 않고 프론트만 실행:

```bash
xcodebuild -scheme KboLivemacOS -project KboLiveApp.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build
launchctl unsetenv KBO_LIVE_BASE_URL
open -n .xcode/DerivedData/Build/Products/Debug/KboLiveApp.app
```

이미 같은 포트에 backend가 떠 있는데 새 환경변수로 다시 실행해야 하면:

```bash
FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

진행 중 경기 UI를 테스트하기 위한 단일 live fixture 실행:

```bash
KBO_USE_TEST_LIVE_GAME=1 FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

### backend spike
```bash
cd backend-spike
npm install
npm run dev
```

백그라운드 실행/종료:
```bash
./scripts/backend-start.sh
./scripts/backend-stop.sh
```

로그:
```bash
tail -f backend-spike/logs/backend.log
```

Xcode 실행 전에 자동으로 백엔드를 켜고 싶으면 scheme의 `Run > Pre-actions`에 아래 스크립트를 넣습니다.

```bash
/Users/suhohan/Projects/kbo-live/scripts/backend-start.sh
```

Mac mini 테스트용 runtime 패키징:

```bash
./scripts/package-macmini-runtime.sh
```

Mac mini로 업로드하고 backend health smoke까지 실행:

```bash
SSH_TARGET=suhohan@100.114.89.25 REMOTE_DIR=/Users/suhohan/Projects/kbo-live ./scripts/deploy-macmini-runtime.sh
```

macOS 배포/원격 테스트 체크리스트는 `PROJECT_CONTEXT/macos-release-operations.md`를 기준으로 유지합니다.

### Swift package
```bash
cd Packages/KboLiveCore
swift test
```

Feature package 검증:

```bash
cd Packages/KboLiveFeatures
swift test
```

전체 로컬 검증:

```bash
./scripts/verify-local.sh
```

Xcode target build를 제외하고 빠르게 확인:

```bash
SKIP_XCODE=1 ./scripts/verify-local.sh
```

MVP 안정화 체크리스트는 `PROJECT_CONTEXT/mvp-stability-checklist.md`를 기준으로 유지합니다.

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
- `KBO_LIVE_BASE_URL`을 지정하지 않으면 앱 설정 또는 `http://127.0.0.1:17361` 백엔드를 사용합니다.
- 앱의 API client는 기본적으로 `/v1` endpoint를 호출합니다.
- iOS/macOS 앱의 설정 화면에서 `Local`, `Staging`, `Production` backend preset을 선택하고 Backend URL을 저장할 수 있습니다.
- `KBO_LIVE_BASE_URL` 환경변수가 있으면 앱 설정값보다 우선합니다.
- `KBO_LIVE_STAGING_BASE_URL`, `KBO_LIVE_PRODUCTION_BASE_URL`을 지정하면 설정 화면의 Staging/Production preset 초기 URL로 사용합니다.

로컬 검증에 사용한 명령:
```bash
xcodebuild -scheme KboLivemacOS -project KboLiveApp.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build

xcodebuild -scheme KboLiveiOS -project KboLiveApp.xcodeproj -destination 'generic/platform=iOS Simulator' -derivedDataPath .xcode/DerivedData build
```

### Live fixture 수집

경기 중 polling fixture를 수집:

```bash
./scripts/run-kbo-live-fixture-capture.sh 20260616
```

생성 경로:

```text
backend-spike/logs/polling/<YYYYMMDD>/
backend-spike/fixtures/live-<YYYYMMDD>/
```

## 참고 문서
- `PROJECT_CONTEXT/README.md`
- `PROJECT_CONTEXT/xcode-project-structure.md`
- `PROJECT_CONTEXT/forward-development-roadmap.md`
- `PROJECT_CONTEXT/backend-spike-results.md`
- `PROJECT_CONTEXT/production-backend-strategy.md`
- `PROJECT_CONTEXT/kbo-data-quality-regression-plan.md`
- `PROJECT_CONTEXT/kbo-data-validation-checklist.md`
- `PROJECT_CONTEXT/kbo-source-data-collection.md`
- `PROJECT_CONTEXT/app-productization-roadmap.md`
