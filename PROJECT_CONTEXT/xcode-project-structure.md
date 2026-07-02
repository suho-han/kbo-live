# Baseball LIVE KR Project Structure

작성일: 2026-06-13  
업데이트: 2026-06-14  
상태: Current

이 문서는 현재 `kbo-live` 저장소의 실제 구조와 개발 진입점을 정리한 기준 문서다.

## 1. 현재 목표

- iOS에서 오늘 경기와 라이브 상태를 보여주는 앱 기반 유지
- macOS Menu Bar 앱 기반 유지
- Widget / Live Activity 타깃 유지
- KBO 데이터 수집용 backend spike 유지
- Core / DesignSystem / Features 계층 분리 유지

## 2. 저장소 루트

```text
AGENTS.md
README.md
project.yml
BaseballLiveKRApp/
BaseballLiveKR.xcodeproj/
BaseballLiveKR.xcworkspace/
Packages/
PROJECT_CONTEXT/
backend-spike/
scripts/
```

역할:

- `project.yml`
  - XcodeGen으로 실제 프로젝트를 생성하는 단일 정의 파일
- `BaseballLiveKRApp/`
  - iOS, macOS, Widget 타깃용 앱 소스
- `BaseballLiveKR.xcodeproj/`
  - 현재 빌드 검증에 사용한 실제 프로젝트
- `BaseballLiveKR.xcworkspace/`
  - 루트 워크스페이스
  - 현재 샌드박스에서는 `xcodebuild -workspace` 검증이 안정적이지 않음
- `Packages/`
  - Core, DesignSystem, Features Swift 패키지
- `backend-spike/`
  - KBO 데이터 수집/정규화 스파이크

## 3. 현재 앱 연결 방식

현재 app target은 local package dependency를 직접 연결하지 않고, 각 package의 source directory를 Xcode target source로 직접 포함한다.

이유:

- 현재 샌드박스 환경에서 local Swift package resolution이 불안정했다.
- 빌드 검증을 우선 통과시키기 위해 source 직접 포함 방식으로 고정했다.
- package 구조 자체는 유지하므로, 나중에 dependency 방식으로 다시 전환할 수 있다.

의존 방향:

```text
BaseballLiveKRCore
  -> domain / dto / mapper / repository / polling / projections

BaseballLiveKRDesignSystem
  -> reusable SwiftUI tokens / themes / components

BaseballLiveKRFeatures
  -> screen-level UI and view model

BaseballLiveKRApp targets
  -> compose Core + DesignSystem + Features + platform entrypoints
```

## 4. Xcode 타깃

`project.yml` 기준 현재 타깃:

- `BaseballLiveKRiOS`
  - iOS app
  - product name: `BaseballLiveKR`
  - bundle id: `kr.suhohan.baseballlivekr.ios`
  - Live Activities 활성화
- `BaseballLiveKRmacOS`
  - macOS app
  - product name: `BaseballLiveKR`
  - bundle id: `kr.suhohan.baseballlivekr.macos`
  - `MenuBarExtra` 기반 엔트리 포함
- `BaseballLiveKRWidgetExtension`
  - iOS widget extension
  - bundle id: `kr.suhohan.baseballlivekr.ios.widget`
  - Today widget + Live Activity widget 포함

배포 타깃:

- iOS 18.0
- macOS 15.0

공통 설정:

- Swift 6.0
- `MARKETING_VERSION = 0.1.0`
- `CURRENT_PROJECT_VERSION = 1`

## 5. BaseballLiveKRApp 구조

```text
BaseballLiveKRApp/
  Shared/
  iOS/
  macOS/
  Widget/
```

주요 파일:

- `BaseballLiveKRApp/Shared/AppRuntime.swift`
- `BaseballLiveKRApp/Shared/BaseballLiveKRHomeRootView.swift`
- `BaseballLiveKRApp/Shared/SampleGameFactory.swift`
- `BaseballLiveKRApp/iOS/BaseballLiveKRiOSApp.swift`
- `BaseballLiveKRApp/macOS/BaseballLiveKRmacOSApp.swift`
- `BaseballLiveKRApp/macOS/MenuBarDashboardView.swift`
- `BaseballLiveKRApp/Widget/BaseballLiveKRWidgetBundle.swift`
- `BaseballLiveKRApp/Widget/TodayGameWidget.swift`
- `BaseballLiveKRApp/Widget/LiveGameActivityWidget.swift`

## 6. Swift Packages

### `Packages/BaseballLiveKRCore`

책임:

- API client
- DTO / domain
- mapper
- repository
- polling service
- widget / live activity / menu bar projection
- today games 정렬/필터 공용 규칙

핵심 포인트:

- `TodayGames.orderedGames(filter:)` 공용 정렬/필터 제공
- 상태 우선순위: `live -> scheduled -> delayed -> final -> cancelled -> unknown`
- `scheduled` 필터는 `delayed` 포함
- `final` 필터는 `cancelled` 포함

### `Packages/BaseballLiveKRDesignSystem`

책임:

- 팀 색상 체계
- typography / spacing / radius / shadow 토큰
- 재사용 가능한 SwiftUI primitive/component

### `Packages/BaseballLiveKRFeatures`

책임:

- 화면 단위 feature 조합
- 화면 상태와 UI 로직을 묶는 view model

현재 포함 기능:

- `TodayGamesView`
- `TodayGamesViewModel`

핵심 포인트:

- `ObservableObject` + `@Published` 기반
- 로딩 / 리프레시 / 에러 / 필터 상태 관리
- 경기 정렬은 `BaseballLiveKRCore` 공용 규칙 재사용

## 7. Backend Spike

`backend-spike/`는 프로덕션 백엔드가 아니라 데이터 수집과 정규화 검증용 실험 영역이다.

현재 범위:

- Fastify 서버
- KBO source 호출
- month-level schedule loading
- schedule metadata normalization
- fixture dump
- polling 로그 저장
- `today`, `game detail`, `debug source` endpoint

로컬 실행:

```bash
./scripts/backend-start.sh
./scripts/backend-stop.sh
```

macOS 앱 연결:

- 기본 backend URL: `http://127.0.0.1:3000`
- `BASEBALL_LIVE_KR_BASE_URL` 환경변수로 override 가능
- 메뉴바에서 설정, 메인 창, 서버 상태 확인 버튼을 같은 행에 표시
- 서버 상태는 `/health`를 5초 주기로 확인

## 8. 개발 진입점

현재 가장 안전한 진입점:

1. `project.yml`에서 프로젝트 재생성
2. `BaseballLiveKR.xcodeproj` 오픈
3. 원하는 스킴 빌드

재생성:

```bash
/private/tmp/XcodeGen/.build/release/xcodegen generate
```

오픈:

```bash
open BaseballLiveKR.xcodeproj
```

검증된 빌드:

```bash
env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme BaseballLiveKRmacOS -project BaseballLiveKR.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build

env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme BaseballLiveKRiOS -project BaseballLiveKR.xcodeproj -destination 'generic/platform=iOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build

env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme BaseballLiveKRWidgetExtension -project BaseballLiveKR.xcodeproj -destination 'generic/platform=iOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build
```

최근 확인 상태:

- `BaseballLiveKRmacOS`: build succeeded
- `BaseballLiveKRiOS`: build succeeded
- `BaseballLiveKRWidgetExtension`: build succeeded

## 9. 현재 제약

- 루트 `BaseballLiveKR.xcworkspace`는 존재하지만, 현재 샌드박스에서는 `xcodebuild -workspace BaseballLiveKR.xcworkspace` 검증이 안정적이지 않았다.
- app target은 package dependency 방식이 아니라 source 직접 포함 방식이다.
- `BaseballLiveKRFeatures`는 아직 Today Games 중심의 최소 기능만 포함한다.

## 10. 다음 확장 후보

- 실제 API 환경을 붙이는 repository 주입 경로 확장
- 경기 상세 화면 추가
- widget timeline / live activity update 전략 구체화
- macOS menu bar interaction 고도화
- package dependency 기반 Xcode 연결 복구
