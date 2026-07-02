# KBO Live Swift App Bootstrap Files

작성일: 2026-06-10
상태: Working v0.2
개발 환경: 로컬 Mac + Xcode 16 이상 가정

업데이트 메모 (2026-06-10):
- `Packages/BaseballLiveKRCore` 최소 DTO/domain/mapper/test scaffold 생성 완료
- `TodayGamesResponseDTO`, `GameDetailResponseDTO`, `GameDTO` 및 하위 DTO 초안 코드 작성 완료
- `GameDTO -> Game` mapper 초안 작성 완료
- widget / live activity / menu bar용 shared projection(`WidgetGameSnapshot`, `ActivityGameState`, `MenuBarGameSummary`) 및 mapper 초안 추가 완료
- `Packages/BaseballLiveKRDesignSystem` package 및 token/theme/primitive scaffold 추가 완료
- fixture 기반 decode/mapper/projection 테스트 파일 추가 완료
- 단, 현재 Linux 호스트에는 Swift toolchain이 없어 `swift test` 실행 검증은 아직 미완료

## 1. 목표

Swift/Xcode 작업을 시작할 때 **처음 생성할 파일과 폴더를 정확히 정의**한다.

이 문서는 아키텍처 설명보다 한 단계 더 내려가서:
- 어떤 target을 만들지
- 어떤 Swift Package를 연결할지
- 어떤 파일을 제일 먼저 생성할지
- 각 파일이 어떤 책임만 가질지
를 빠르게 결정하기 위한 bootstrap 기준이다.

---

## 2. 초기 생성 범위

MVP 1차 범위:
- iOS App
- Widget Extension
- Live Activity Extension
- macOS Menu Bar App
- Shared Swift Package 2개
  - `BaseballLiveKRCore`
  - `BaseballLiveKRDesignSystem`

초기에는 아래 원칙을 유지한다.
- feature package 분리는 하지 않음
- app target은 얇게 유지
- domain / DTO / networking / repository는 `BaseballLiveKRCore`로 집중
- UI 토큰 / primitive는 `BaseballLiveKRDesignSystem`로 집중

---

## 3. 권장 루트 구조

```text
kbo-live/
├── KboLive.xcworkspace
├── BaseballLiveKRApp/
│   ├── BaseballLiveKRApp.xcodeproj
│   ├── BaseballLiveKRiOS/
│   ├── BaseballLiveKRmacOS/
│   ├── BaseballLiveKRWidgetExtension/
│   └── KboLiveActivityExtension/
├── Packages/
│   ├── BaseballLiveKRCore/
│   └── BaseballLiveKRDesignSystem/
├── backend-spike/
└── PROJECT_CONTEXT/
```

---

## 4. Xcode target 생성 순서

### Step 1. Workspace
- `KboLive.xcworkspace`

### Step 2. App project
- `BaseballLiveKRApp/BaseballLiveKRApp.xcodeproj`

### Step 3. iOS app target
- target name: `BaseballLiveKRiOS`
- interface: SwiftUI
- lifecycle: SwiftUI App
- tests: 기본 unit test target 생성

### Step 4. Widget extension
- target name: `BaseballLiveKRWidgetExtension`
- widget kind는 추후 분리 가능하지만 초기엔 하나의 bundle로 시작

### Step 5. Live Activity extension
- target name: `KboLiveActivityExtension`
- ActivityKit / WidgetKit 기반

### Step 6. macOS target
- target name: `BaseballLiveKRmacOS`
- SwiftUI App
- `MenuBarExtra` 사용

### Step 7. Swift Packages 연결
- local package: `Packages/BaseballLiveKRCore`
- local package: `Packages/BaseballLiveKRDesignSystem`

---

## 5. iOS App 초기 파일 세트

```text
BaseballLiveKRApp/BaseballLiveKRiOS/
├── App/
│   ├── BaseballLiveKRiOSApp.swift
│   ├── AppContainer.swift
│   ├── AppRouter.swift
│   └── AppScenePhaseHandler.swift
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── HomeSection.swift
│   │   └── Components/
│   │       ├── HomeGameCardScoreboard.swift
│   │       └── HomeGameCardBroadcast.swift
│   ├── GameDetail/
│   │   ├── GameDetailView.swift
│   │   ├── GameDetailViewModel.swift
│   │   └── Components/
│   │       ├── GameHeaderScoreboard.swift
│   │       ├── GameHeaderBroadcast.swift
│   │       └── InningLineScoreView.swift
│   ├── Favorites/
│   │   ├── FavoritesView.swift
│   │   └── FavoritesViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   └── LiveActivityControl/
│       ├── LiveActivityControlButton.swift
│       └── LiveActivityCoordinator.swift
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   └── Preview/
│       └── PreviewContainer.swift
└── Resources/
```

### 파일 책임
- `BaseballLiveKRiOSApp.swift`
  - 앱 entry point
  - 루트 scene만 선언
- `AppContainer.swift`
  - repository / service / environment 주입
- `AppRouter.swift`
  - home → detail 이동 경로 정의
- `AppScenePhaseHandler.swift`
  - foreground polling / refresh 정책 연결
- `HomeViewModel.swift`
  - 오늘 경기 목록 조회, 필터, refresh
- `GameDetailViewModel.swift`
  - 단건 경기 상태, 상세 섹션 구성
- `LiveActivityCoordinator.swift`
  - ActivityKit 시작/업데이트/종료 진입점

---

## 6. macOS App 초기 파일 세트

```text
BaseballLiveKRApp/BaseballLiveKRmacOS/
├── App/
│   ├── BaseballLiveKRmacOSApp.swift
│   └── MacAppContainer.swift
├── MenuBar/
│   ├── MenuBarRoot.swift
│   ├── MenuBarLabelView.swift
│   ├── MenuBarDropdownView.swift
│   ├── MenuBarGameRow.swift
│   └── MenuBarRefreshController.swift
├── Windows/
│   └── GameDetailWindowLauncher.swift
├── Settings/
│   └── MacSettingsView.swift
└── Resources/
```

### 파일 책임
- `MenuBarLabelView.swift`
  - 상단 바에 들어갈 가장 짧은 상태 문자열
- `MenuBarDropdownView.swift`
  - 진행 중 경기 우선 목록
- `MenuBarRefreshController.swift`
  - 메뉴바 refresh 트리거, throttling, 앱 active 상태 연계
- `GameDetailWindowLauncher.swift`
  - 클릭 시 상세 창/딥링크 오픈

---

## 7. Widget Extension 초기 파일 세트

```text
BaseballLiveKRApp/BaseballLiveKRWidgetExtension/
├── KboLiveWidgetBundle.swift
├── Providers/
│   ├── FavoriteGameTimelineProvider.swift
│   └── TodayGamesTimelineProvider.swift
├── Models/
│   ├── WidgetGameEntry.swift
│   └── WidgetGameSnapshot.swift
├── Mappers/
│   └── WidgetGameMapper.swift
└── Views/
    ├── SmallGameWidgetView.swift
    ├── MediumGameWidgetView.swift
    └── WidgetEmptyStateView.swift
```

### 파일 책임
- `WidgetGameEntry.swift`
  - `TimelineEntry`
- `WidgetGameSnapshot.swift`
  - widget 전용 경량 표시 모델
- `WidgetGameMapper.swift`
  - `GameDTO`/domain → widget snapshot 변환

원칙:
- widget에서 전체 domain 모델을 직접 UI에 뿌리지 않음
- widget용 축약 모델을 둠

---

## 8. Live Activity Extension 초기 파일 세트

```text
BaseballLiveKRApp/KboLiveActivityExtension/
├── KboLiveActivityAttributes.swift
├── KboLiveActivityWidget.swift
├── Models/
│   └── ActivityGameState.swift
├── Mappers/
│   └── ActivityGameStateMapper.swift
└── Views/
    ├── LockScreenGameView.swift
    ├── DynamicIslandCompactView.swift
    ├── DynamicIslandMinimalView.swift
    └── DynamicIslandExpandedView.swift
```

### 파일 책임
- `KboLiveActivityAttributes.swift`
  - 경기 ID, 팀 식별자 같은 비교적 안정적인 static data
- `ActivityGameState.swift`
  - 점수, 이닝, 아웃, 주자 상태, 최근 플레이 일부 같은 small dynamic state
- `ActivityGameStateMapper.swift`
  - shared DTO/domain → Activity state 축약

원칙:
- Live Activity state는 매우 작게 유지
- 업데이트 빈도가 높은 필드만 넣음
- 전체 `Game` 모델 복사 금지

---

## 9. BaseballLiveKRCore 초기 파일 세트

```text
Packages/BaseballLiveKRCore/
├── Package.swift
├── Sources/
│   └── BaseballLiveKRCore/
│       ├── Config/
│       │   ├── AppEnvironment.swift
│       │   ├── APIEnvironment.swift
│       │   └── FeatureFlags.swift
│       ├── Domain/
│       │   ├── Team.swift
│       │   ├── Game.swift
│       │   ├── GameStatus.swift
│       │   ├── Score.swift
│       │   ├── InningState.swift
│       │   ├── CountState.swift
│       │   ├── BasesState.swift
│       │   ├── CurrentMatchup.swift
│       │   ├── ProbablePitchers.swift
│       │   └── SourceMeta.swift
│       ├── DTO/
│       │   ├── GameDTO.swift
│       │   ├── TodayGamesResponseDTO.swift
│       │   ├── GameDetailResponseDTO.swift
│       │   ├── WidgetGameSnapshotDTO.swift
│       │   └── ActivityGameStateDTO.swift
│       ├── API/
│       │   ├── APIClient.swift
│       │   ├── KboLiveAPIClient.swift
│       │   ├── APIRequestBuilder.swift
│       │   └── APIError.swift
│       ├── Repository/
│       │   ├── GameRepository.swift
│       │   ├── DefaultGameRepository.swift
│       │   └── MockGameRepository.swift
│       ├── Services/
│       │   ├── LiveGamePollingService.swift
│       │   ├── WidgetSnapshotService.swift
│       │   └── LiveActivityProjectionService.swift
│       ├── Mappers/
│       │   ├── GameDTOMapper.swift
│       │   ├── WidgetGameSnapshotMapper.swift
│       │   └── ActivityGameStateMapper.swift
│       ├── Formatting/
│       │   ├── ScoreboardFormatter.swift
│       │   ├── InningFormatter.swift
│       │   ├── CountFormatter.swift
│       │   └── MenuBarFormatter.swift
│       ├── Mocks/
│       │   ├── MockGameFactory.swift
│       │   └── MockResponseLoader.swift
│       └── Utils/
│           ├── DateFormatting.swift
│           └── ISO8601KSTParser.swift
└── Tests/
    └── BaseballLiveKRCoreTests/
        ├── DTO/
        ├── Mappers/
        ├── Repository/
        ├── Formatting/
        └── Services/
```

### 가장 먼저 만드는 파일 우선순위
1. `Package.swift`
2. `GameDTO.swift`
3. `TodayGamesResponseDTO.swift`
4. `Game.swift`
5. `GameStatus.swift`
6. `KboLiveAPIClient.swift`
7. `GameRepository.swift`
8. `DefaultGameRepository.swift`
9. `GameDTOMapper.swift`
10. `MockGameFactory.swift`

---

## 10. BaseballLiveKRDesignSystem 초기 파일 세트

```text
Packages/BaseballLiveKRDesignSystem/
├── Package.swift
├── Sources/
│   └── BaseballLiveKRDesignSystem/
│       ├── Tokens/
│       │   ├── KboColorToken.swift
│       │   ├── KboSpacingToken.swift
│       │   ├── KboTypographyToken.swift
│       │   ├── KboRadiusToken.swift
│       │   └── KboShadowToken.swift
│       ├── Theme/
│       │   ├── KboTheme.swift
│       │   └── TeamColorPalette.swift
│       ├── Components/
│       │   ├── TeamBadgeView.swift
│       │   ├── ScoreDigitsView.swift
│       │   ├── LiveBadgeView.swift
│       │   ├── InningStateView.swift
│       │   ├── OutCountView.swift
│       │   ├── BaseDiamondView.swift
│       │   └── PitchCountView.swift
│       └── Helpers/
│           └── TeamColorResolver.swift
└── Tests/
    └── BaseballLiveKRDesignSystemTests/
```

---

## 11. Xcode Build Settings / Capability 체크포인트

### iOS App
- Background Modes는 초기에 과도하게 열지 않음
- Live Activities capability 활성화
- App Group은 widget/live activity shared storage가 필요해지는 시점에 추가

### Widget Extension
- WidgetKit 설정
- App Group 필요 여부 검토

### Live Activity Extension
- ActivityKit 사용
- push update는 후순위, 초기는 local update 기준

### macOS App
- sandbox와 외부 네트워크 접근 범위 점검
- 메뉴바 전용 UX로 시작, 복잡한 multi-window는 후순위

---

## 12. Bootstrap 완료 기준

다음이 보이면 bootstrap 완료로 본다.
- Xcode workspace 생성 완료
- 4개 target 생성 완료
- 2개 local package 연결 완료
- iOS Home mock 화면 preview 표시 가능
- Widget placeholder 표시 가능
- Live Activity preview 표시 가능
- macOS MenuBarExtra placeholder 표시 가능
- `BaseballLiveKRCore`에서 mock `TodayGamesResponseDTO` decode 테스트 1개 통과

---

## 13. 현재 추천 결론

처음부터 feature를 세밀하게 쪼개기보다:
- **app targets는 얇은 shell**
- **BaseballLiveKRCore는 데이터/도메인 중심**
- **BaseballLiveKRDesignSystem은 표현 중심**
으로 나누는 것이 가장 안전하다.

초기 1~2일은 실제 기능 구현보다,
1. Xcode target 구조 안정화
2. shared DTO / domain 타입 확정
3. mock preview 생산성 확보
에 쓰는 것이 이후 속도를 가장 크게 올린다.
