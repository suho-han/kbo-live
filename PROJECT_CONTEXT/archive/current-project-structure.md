# Current Project Structure

이 문서는 2026-06-13 기준 `kbo-live` 저장소의 실제 구성과 빌드 진입점을 정리한 현재 시점 스냅샷이다.

## 목적

- iOS에서 KBO 오늘 경기와 라이브 상태를 보여주는 앱 기반 구축
- macOS Menu Bar 앱 기반 구축
- Widget / Live Activity 기반 구축
- KBO 데이터 수집용 백엔드 스파이크 유지
- Swift 패키지 단위로 domain, UI, feature 계층 분리

## 저장소 루트 구성

```text
AGENTS.md
README.md
project.yml
BaseballLiveKRApp/
BaseballLiveKRApp.xcodeproj/
KboLive.xcworkspace/
Packages/
PROJECT_CONTEXT/
backend-spike/
scripts/
```

각 경로의 역할:

- `AGENTS.md`
  - 이 저장소 전용 응답 규칙과 Discord 알림 규칙을 정의한다.
- `README.md`
  - 빠른 시작, 빌드 진입점, 상위 문서 링크를 제공한다.
- `project.yml`
  - XcodeGen으로 실제 Xcode 프로젝트를 생성하는 단일 정의 파일이다.
- `BaseballLiveKRApp/`
  - iOS, macOS, Widget 타깃이 공유하는 앱 소스 트리다.
- `BaseballLiveKRApp.xcodeproj/`
  - 현재 빌드 검증에 사용한 실제 Xcode 프로젝트다.
- `KboLive.xcworkspace/`
  - 루트 워크스페이스 파일이다. 현재 샌드박스에서는 `xcodebuild -workspace` 검증이 안정적이지 않다.
- `Packages/`
  - Core, DesignSystem, Features 계층을 나눈 Swift 패키지 모음이다.
- `PROJECT_CONTEXT/`
  - 제품 계획, 구조 설계, 스파이크 결과 문서를 보관한다.
- `backend-spike/`
  - KBO 데이터 소스 검증용 Fastify + TypeScript 실험 코드다.
- `scripts/`
  - 개발 보조 스크립트를 둔다.

## 앱 계층 구조

현재 앱 계층은 Xcode에서 로컬 Swift package dependency를 직접 물리는 대신, app target이 각 package의 source directory를 직접 포함하는 방식으로 연결되어 있다.

이 선택의 이유:

- 현재 샌드박스/Xcode 환경에서 local package resolution이 불안정했다.
- 빌드 검증을 우선 통과시키기 위해 소스 직접 포함 방식으로 프로젝트를 고정했다.
- 패키지 자체는 그대로 유지하므로 향후 workspace/package dependency 기반으로 다시 전환할 수 있다.

의존 방향:

```text
BaseballLiveKRCore
  -> domain / dto / mapper / repository / polling / projections

BaseballLiveKRDesignSystem
  -> reusable SwiftUI token / theme / primitive component

BaseballLiveKRFeatures
  -> screen-level feature UI and view model

BaseballLiveKRApp targets
  -> compose Core + DesignSystem + Features + platform entrypoints
```

## Xcode 프로젝트 구성

`project.yml`에서 정의한 현재 타깃:

- `BaseballLiveKRiOS`
  - iOS application target
  - product name: `BaseballLiveKRiOS`
  - bundle id: `com.suhohan.kbo-live.ios`
  - Live Activities 활성화
- `BaseballLiveKRmacOS`
  - macOS application target
  - product name: `BaseballLiveKRApp`
  - bundle id: `com.suhohan.kbo-live.macos`
  - Menu Bar 앱 진입점 포함
- `BaseballLiveKRWidgetExtension`
  - iOS widget extension target
  - bundle id: `com.suhohan.kbo-live.ios.widget`
  - Today widget + Live Activity widget 포함

배포 타깃:

- iOS 18.0
- macOS 15.0

공통 프로젝트 설정:

- Swift 6.0
- `MARKETING_VERSION = 0.1.0`
- `CURRENT_PROJECT_VERSION = 1`

## BaseballLiveKRApp 디렉터리

```text
BaseballLiveKRApp/
  Shared/
  iOS/
  macOS/
  Widget/
```

세부 역할:

- `BaseballLiveKRApp/Shared/AppRuntime.swift`
  - 앱 전반에서 사용할 환경/주입 지점을 담는 런타임 진입점이다.
- `BaseballLiveKRApp/Shared/KboLiveHomeRootView.swift`
  - 현재 홈 루트 화면이다.
  - `TodayGamesViewModel`을 주입받아 공통 홈 UI를 구성한다.
- `BaseballLiveKRApp/Shared/SampleGameFactory.swift`
  - 앱, 메뉴바, 위젯 프리뷰/샘플 렌더링용 경기 데이터를 만든다.
- `BaseballLiveKRApp/iOS/BaseballLiveKRiOSApp.swift`
  - iOS 앱 엔트리 포인트다.
- `BaseballLiveKRApp/macOS/BaseballLiveKRmacOSApp.swift`
  - macOS 앱 엔트리 포인트다.
  - `MenuBarExtra` 기반 진입을 포함한다.
- `BaseballLiveKRApp/macOS/MenuBarDashboardView.swift`
  - 메뉴바 팝오버/대시보드용 SwiftUI 화면이다.
- `BaseballLiveKRApp/Widget/KboLiveWidgetBundle.swift`
  - 위젯 번들 엔트리다.
- `BaseballLiveKRApp/Widget/TodayGameWidget.swift`
  - 오늘 경기용 홈 위젯이다.
- `BaseballLiveKRApp/Widget/LiveGameActivityWidget.swift`
  - Live Activity용 위젯 정의다.

## Swift Packages 구성

### Packages/BaseballLiveKRCore

역할:

- API client
- DTO / domain model
- mapper
- repository
- live polling service
- widget / live activity / menu bar projection
- today game list 정렬/필터 공용 규칙

주요 소스:

- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/API/KboLiveAPIClient.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/GameFeedClient.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/KboLiveEnvironment.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/TodayGamesList.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/DTO/GameDTO.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/Game.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/GameFeed.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Formatting/GameProjectionFormatter.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/ActivityGameStateMapper.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/GameDTOMapper.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/MenuBarGameSummaryMapper.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/WidgetGameSnapshotMapper.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mocks/MockGameRepository.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Projections/ActivityGameState.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Projections/MenuBarGameSummary.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Projections/WidgetGameSnapshot.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Repository/GameRepository.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Services/LiveGamePollingService.swift`

현재 핵심 포인트:

- `TodayGames.orderedGames(filter:)`로 오늘 경기 정렬/필터 규칙을 공용화했다.
- 상태 우선순위는 `live -> scheduled -> delayed -> final -> cancelled -> unknown`이다.
- `scheduled` 필터는 `delayed`를 포함하고, `final` 필터는 `cancelled`를 포함한다.

테스트:

- API / repository / polling / projection / DTO / today list 정렬 테스트가 존재한다.

### Packages/BaseballLiveKRDesignSystem

역할:

- 공통 SwiftUI 컴포넌트
- 팀 색상 체계
- 타이포그래피, spacing, radius, shadow 토큰

주요 소스:

- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/BaseDiamondView.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/InningStateView.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/LiveBadgeView.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/OutCountView.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/PitchCountView.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/ScoreDigitsView.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/TeamBadgeView.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Helpers/TeamColorResolver.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Theme/KboTheme.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Theme/TeamColorPalette.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboColorToken.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboRadiusToken.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboShadowToken.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboSpacingToken.swift`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboTypographyToken.swift`

### Packages/BaseballLiveKRFeatures

역할:

- 화면 단위 feature 조합
- 화면 상태와 UI 로직을 묶는 view model

현재 포함 기능:

- `TodayGamesView`
- `TodayGamesViewModel`

주요 소스:

- `Packages/BaseballLiveKRFeatures/Sources/BaseballLiveKRFeatures/TodayGames/TodayGamesView.swift`
- `Packages/BaseballLiveKRFeatures/Sources/BaseballLiveKRFeatures/TodayGames/TodayGamesViewModel.swift`

현재 핵심 포인트:

- `TodayGamesViewModel`은 `ObservableObject` + `@Published` 기반이다.
- 로딩, 리프레시, 에러, 필터 변경 상태를 관리한다.
- 경기 정렬은 `BaseballLiveKRCore`의 공용 규칙을 재사용한다.

테스트:

- `Packages/BaseballLiveKRFeatures/Tests/BaseballLiveKRFeaturesTests/TodayGamesViewModelTests.swift`

## backend-spike 구성

`backend-spike/`는 앱 출시용 프로덕션 백엔드가 아니라 데이터 수집/정합성 확인을 위한 실험 영역이다.

현재 포함 범위:

- Fastify 서버
- KBO source 호출
- fixture dump
- polling 로그 저장
- today/game detail/debug endpoint

주요 하위 경로:

- `backend-spike/src/clients`
- `backend-spike/src/config`
- `backend-spike/src/dto`
- `backend-spike/src/mappers`
- `backend-spike/src/models`
- `backend-spike/src/routes`
- `backend-spike/src/services`
- `backend-spike/src/utils`
- `backend-spike/tests`
- `backend-spike/fixtures`
- `backend-spike/logs`

## 빌드와 실행 진입점

현재 가장 신뢰할 수 있는 진입점:

1. `project.yml`을 기준으로 Xcode 프로젝트를 재생성한다.
2. `BaseballLiveKRApp.xcodeproj`를 연다.
3. 필요한 스킴을 선택해 빌드한다.

프로젝트 재생성:

```bash
/private/tmp/XcodeGen/.build/release/xcodegen generate
```

권장 오픈 대상:

```bash
open BaseballLiveKRApp.xcodeproj
```

현재 검증된 빌드 명령:

```bash
env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme BaseballLiveKRmacOS -project BaseballLiveKRApp.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build

env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme BaseballLiveKRiOS -project BaseballLiveKRApp.xcodeproj -destination 'generic/platform=iOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build

env HOME=$PWD/.xcode/home CFFIXED_USER_HOME=$PWD/.xcode/home XDG_CACHE_HOME=$PWD/.xcode/home/Library/Caches \
  xcodebuild -scheme BaseballLiveKRWidgetExtension -project BaseballLiveKRApp.xcodeproj -destination 'generic/platform=iOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build
```

최근 확인 상태:

- `BaseballLiveKRmacOS`: build succeeded
- `BaseballLiveKRiOS`: build succeeded
- `BaseballLiveKRWidgetExtension`: build succeeded

## 현재 제약과 주의사항

- 루트 `KboLive.xcworkspace`는 파일로 존재하지만, 현재 샌드박스에서는 `xcodebuild -workspace KboLive.xcworkspace` 검증이 안정적이지 않았다.
- 따라서 실제 개발 진입점은 현재 기준 `BaseballLiveKRApp.xcodeproj`가 더 안전하다.
- app target은 package dependency 방식이 아니라 소스 직접 포함 방식이라, 나중에 패키지 재구성 시 `project.yml` 수정이 필요하다.
- `BaseballLiveKRFeatures`는 현재 Today Games 중심의 최소 기능만 포함한다.
- 실제 네트워크 연결, 데이터 persistence, 상세 화면, 위젯 timeline 전략은 아직 확장 여지가 크다.

## 다음 확장 후보

- 실제 API 환경을 붙이는 `GameRepository` 주입 경로 추가
- 상세 화면과 경기별 drill-down feature 추가
- widget timeline / live activity update 전략 구체화
- macOS menu bar interaction 고도화
- package dependency 기반 Xcode 연결 복구
