# KBO Live MVP Task Breakdown

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

작성일: 2026-06-10
상태: Draft v0.1
개발 환경: 로컬 Mac + Xcode

**Goal:** iPhone 앱, Widget, Live Activity, macOS 메뉴바를 포함한 KBO Live의 MVP를 로컬 Mac에서 구현하기 위한 실행 가능한 초기 작업 순서를 정의한다.

**Architecture:** Xcode 멀티타깃 구조 위에 Swift Package 기반 shared core를 두고, 먼저 mock 기반 UI 프로토타입을 만든 뒤 실제 KBO 데이터 소스를 연결한다. 데이터 공급은 초기에 polling 기반으로 시작하고, 구조적으로는 추후 push/APNs 확장이 가능하게 설계한다.

**Tech Stack:** Swift 6, SwiftUI, WidgetKit, ActivityKit, MenuBarExtra, SwiftData, URLSession, OSLog

---

## 전제

이 문서는 아직 코드가 없는 상태에서 시작하는 MVP 구현 계획이다.

현재 저장소 상태:
- `/home/suhohan/kbo-live` 는 현재 git repo임
- `backend-spike/` 와 `Packages/BaseballLiveKRCore`, `Packages/BaseballLiveKRDesignSystem` 초안이 이미 존재함
- Xcode project / 실제 Apple target은 아직 없음
- 현재 Linux 호스트에는 Swift toolchain이 없어 Apple 타깃 build 검증은 Mac에서 진행해야 함

---

## Task 1: 저장소/워크스페이스 초기화

**Objective:** 로컬 Mac 개발을 위한 기본 프로젝트 뼈대를 만든다.

**Files:**
- Create: `KboLive.xcworkspace`
- Create: `BaseballLiveKRApp/BaseballLiveKRApp.xcodeproj`
- Create: `PROJECT_CONTEXT/`
- Create: `.gitignore`
- Create: `README.md`

**Step 1: git 저장소 초기화**
- 로컬 Mac에서 프로젝트 루트로 이동
- `git init` 실행

**Step 2: 기본 문서 파일 추가**
- `README.md` 생성
- 프로젝트 목적과 타깃 요약 작성

**Step 3: Xcode workspace / project 생성**
- `KboLive.xcworkspace`
- `BaseballLiveKRApp.xcodeproj`

**Step 4: 기본 ignore 설정 추가**
포함 예시:
- `DerivedData/`
- `.DS_Store`
- `.build/`
- `xcuserdata/`

**Step 5: 검증**
- Finder/Xcode에서 workspace가 정상 열리는지 확인

**Step 6: Commit**
- `chore: initialize repository and Xcode workspace`

---

## Task 2: 멀티타깃 생성

**Objective:** iOS, Widget, Live Activity, macOS 메뉴바 타깃을 생성한다.

**Files:**
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/*`
- Create: `BaseballLiveKRApp/BaseballLiveKRWidgetExtension/*`
- Create: `BaseballLiveKRApp/KboLiveActivityExtension/*`
- Create: `BaseballLiveKRApp/BaseballLiveKRmacOS/*`

**Step 1: iOS App target 생성**
- SwiftUI App lifecycle 사용

**Step 2: Widget Extension 추가**
- Small/Medium widget용

**Step 3: Live Activity Extension 추가**
- ActivityKit 포함

**Step 4: macOS App target 추가**
- MenuBarExtra 기반

**Step 5: signing/capabilities 기본 점검**
- Widget/Activity capability 연결 가능 여부 확인

**Step 6: 검증**
- 각 타깃이 build settings에서 보이는지 확인
- 빈 상태로 build 가능 여부 확인

**Step 7: Commit**
- `chore: add iOS widget live activity and macOS targets`

---

## Task 3: Shared Package 생성

**Objective:** 공용 로직을 담을 Swift Package를 만든다.

**Files:**
- Create: `Packages/BaseballLiveKRCore/Package.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/`
- Create: `Packages/BaseballLiveKRDesignSystem/Package.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/`

**Step 1: `BaseballLiveKRCore` package 생성**
- domain/api/repository/services/formatting 폴더 틀 생성

**Step 2: `BaseballLiveKRDesignSystem` package 생성**
- tokens/components/theme 폴더 틀 생성

**Step 3: Xcode workspace에 package 연결**
- iOS/macOS/widget/activity 타깃에 연결

**Step 4: 검증**
- 모든 타깃이 package import 가능해야 함

**Step 5: Commit**
- `chore: add shared core and design system packages`

---

## Task 4: 도메인 모델 최소 세트 정의

**Objective:** MVP에 필요한 최소 도메인 모델을 정의한다.

**Files:**
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/Team.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/Game.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/Score.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/GameStatus.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/InningState.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/BasesState.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/RecentPlay.swift`
- Test: `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/Domain/`

**Step 1: Team 모델 작성**
**Step 2: Game/Score/GameStatus 모델 작성**
**Step 3: Inning/Bases/RecentPlay 모델 작성**
**Step 4: Codable/Hashable/Equatable 등 필요 프로토콜 정리**
**Step 5: 간단한 테스트 추가**

**Step 6: 검증**
- Core package test/build 성공

**Step 7: Commit**
- `feat: add core KBO game domain models`

---

## Task 5: 디자인 토큰 정의

**Objective:** KBO 스타일 UI에 필요한 디자인 토큰을 정의한다.

**Files:**
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboColorToken.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboTypographyToken.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/KboSpacingToken.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/TeamColorPalette.swift`

**Step 1: 다크 배경/텍스트 토큰 작성**
**Step 2: 상태 색상 토큰 작성**
**Step 3: 팀별 accent color 매핑 작성**
**Step 4: typography/spacing token 정리**

**Step 5: 검증**
- Preview에서 import 가능한지 확인

**Step 6: Commit**
- `feat: add KBO design tokens and team color palette`

---

## Task 6: 핵심 Primitive 컴포넌트 작성

**Objective:** 재사용 가능한 KBO 핵심 UI primitive를 만든다.

**Files:**
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/TeamBadgeView.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/ScoreDigitsView.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/LiveBadgeView.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/OutCountView.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/BaseDiamondView.swift`
- Create: `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/RecentPlayTickerView.swift`

**Step 1: TeamBadgeView 구현**
**Step 2: ScoreDigitsView 구현**
**Step 3: LiveBadgeView 구현**
**Step 4: OutCountView 구현**
**Step 5: BaseDiamondView 구현**
**Step 6: RecentPlayTickerView 구현**

**Step 7: 검증**
- 각 컴포넌트 Preview 확인

**Step 8: Commit**
- `feat: add core scoreboard UI primitives`

---

## Task 7: Mock 데이터 팩토리 작성

**Objective:** 로컬 Mac에서 실제 API 없이 UI를 빠르게 확인할 mock 데이터를 만든다.

**Files:**
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mocks/MockTeamFactory.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mocks/MockGameFactory.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mocks/MockRecentPlayFactory.swift`

**Step 1: 예정 경기 mock 작성**
**Step 2: LIVE 경기 mock 작성**
**Step 3: 종료 경기 mock 작성**
**Step 4: 긴장 상황(9회말 2사 만루) mock 작성**
**Step 5: 우천 지연 mock 작성**

**Step 6: 검증**
- Preview에 주입해서 정상 표시 확인

**Step 7: Commit**
- `feat: add mock game factories for previews`

---

## Task 8: Home 카드 A/B 구현

**Objective:** 전광판형/방송중계형 홈 경기 카드를 구현한다.

**Files:**
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/Home/Components/HomeGameCardA.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/Home/Components/HomeGameCardB.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/Home/HomePreviewGallery.swift`

**Step 1: HomeGameCardA 구현**
**Step 2: HomeGameCardB 구현**
**Step 3: 동일 mock으로 A/B 비교 preview 작성**

**Step 4: 검증**
- 점수/회차/주자 상태가 작은 폭에서도 읽히는지 확인

**Step 5: Commit**
- `feat: add A/B home game card prototypes`

---

## Task 9: 상세 헤더 A/B 구현

**Objective:** 상세 상단 헤더의 A/B 레이아웃을 만든다.

**Files:**
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/GameDetail/Components/GameDetailHeaderA.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/GameDetail/Components/GameDetailHeaderB.swift`

**Step 1: 전광판형 상세 헤더 구현**
**Step 2: 방송중계형 상세 헤더 구현**
**Step 3: PitchCount/BaseDiamond/RecentPlay 연결**

**Step 4: 검증**
- 현재 장면 이해가 쉬운지 preview로 비교

**Step 5: Commit**
- `feat: add A/B game detail header prototypes`

---

## Task 10: Widget A/B 구현

**Objective:** Small/Medium 위젯의 기본 프로토타입을 만든다.

**Files:**
- Create: `BaseballLiveKRApp/BaseballLiveKRWidgetExtension/Views/SmallGameWidgetA.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRWidgetExtension/Views/SmallGameWidgetB.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRWidgetExtension/Views/MediumGameWidgetA.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRWidgetExtension/Views/MediumGameWidgetB.swift`

**Step 1: Small A/B 구현**
**Step 2: Medium A/B 구현**
**Step 3: static preview snapshot 작성**

**Step 4: 검증**
- 좁은 공간에서 A/B 어느 쪽이 더 읽기 쉬운지 확인

**Step 5: Commit**
- `feat: add widget A/B prototypes`

---

## Task 11: Live Activity A/B 구현

**Objective:** Lock Screen과 Dynamic Island의 기본 프로토타입을 만든다.

**Files:**
- Create: `BaseballLiveKRApp/KboLiveActivityExtension/KboLiveActivityAttributes.swift`
- Create: `BaseballLiveKRApp/KboLiveActivityExtension/Models/ActivityGameState.swift`
- Create: `BaseballLiveKRApp/KboLiveActivityExtension/Views/LockScreenGameViewA.swift`
- Create: `BaseballLiveKRApp/KboLiveActivityExtension/Views/LockScreenGameViewB.swift`
- Create: `BaseballLiveKRApp/KboLiveActivityExtension/Views/DynamicIslandCompactView.swift`
- Create: `BaseballLiveKRApp/KboLiveActivityExtension/Views/DynamicIslandExpandedView.swift`

**Step 1: Activity attributes 정의**
**Step 2: 경량 Activity state 모델 정의**
**Step 3: Lock Screen A/B 구현**
**Step 4: Compact/Expanded Island 구현**

**Step 5: 검증**
- iPhone simulator / preview에서 레이아웃 확인

**Step 6: Commit**
- `feat: add live activity A/B prototypes`

---

## Task 12: macOS Menu Bar MVP 구현

**Objective:** 맥 메뉴바에서 현재 경기 한 줄과 드롭다운을 표시한다.

**Files:**
- Create: `BaseballLiveKRApp/BaseballLiveKRmacOS/MenuBar/MenuBarRoot.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRmacOS/MenuBar/MenuBarLabelView.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRmacOS/MenuBar/MenuBarDropdownView.swift`
- Create: `BaseballLiveKRApp/BaseballLiveKRmacOS/MenuBar/MenuBarGameRow.swift`

**Step 1: MenuBarExtra 엔트리 생성**
**Step 2: 기본 ticker label 구현**
**Step 3: 드롭다운 경기 row 구현**
**Step 4: mock 데이터 연결**

**Step 5: 검증**
- macOS target 실행 후 메뉴바 표시 확인

**Step 6: Commit**
- `feat: add macOS menu bar MVP shell`

---

## Task 13: A/B 선택 결정 문서화

**Objective:** Home/Detail/Widget/Live Activity의 A/B 결과를 비교하고 1차 선택안을 기록한다.

**Files:**
- Create: `PROJECT_CONTEXT/ui-tone-decision.md`

**Step 1: 비교 기준 정리**
- 인지 속도
- 가독성
- 공간 효율
- KBO 감성

**Step 2: 화면별 1차 선택 기록**
- Home
- Detail Header
- Widget
- Live Activity
- Menu bar

**Step 3: 남길 혼합 전략 기록**
- 예: global A + detail B

**Step 4: Commit**
- `docs: record initial UI tone decisions`

---

## Task 14: 실제 데이터 소스 추상화 추가

**Objective:** mock에서 실제 KBO 데이터 연결로 넘어가기 위한 추상화를 만든다.

**Files:**
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/API/KboAPIClient.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/API/KboRequestBuilder.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/API/KboDataSource.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Repository/GameRepository.swift`

**Step 1: DataSource 프로토콜 정의**
**Step 2: MockDataSource 구현**
**Step 3: OfficialKboDataSource 골격 구현**
**Step 4: Repository가 DataSource에 의존하도록 연결**

**Step 5: 검증**
- mock과 real source를 교체 가능해야 함

**Step 6: Commit**
- `feat: add data source abstraction for KBO game data`

---

## Task 15: KBO 일정/경기 목록 API 연결

**Objective:** 공식 KBO 소스에서 경기 목록과 기본 상태를 가져온다.

**Files:**
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/DTO/KboGameListResponseDTO.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/DTO/KboScheduleListResponseDTO.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/API/OfficialKboAPIClient.swift`
- Test: `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/API/OfficialKboAPIClientTests.swift`

**Step 1: `GetKboGameDate` 응답 DTO 작성**
**Step 2: `GetKboGameList` 응답 DTO 작성**
**Step 3: `GetScheduleList` 응답 DTO 작성**
**Step 4: domain mapper 작성**
**Step 5: 정상 파싱 테스트 작성**

**Step 6: 검증**
- 날짜/경기목록/선발/기본 점수 매핑 확인

**Step 7: Commit**
- `feat: connect official KBO game list endpoints`

---

## Task 16: Polling 서비스 연결

**Objective:** 앱 foreground에서 일정 주기로 경기 상태를 갱신한다.

**Files:**
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Services/LiveGamePollingService.swift`
- Modify: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/Home/HomeViewModel.swift`
- Modify: `BaseballLiveKRApp/BaseballLiveKRmacOS/MenuBar/MenuBarRoot.swift`

**Step 1: polling service 작성**
**Step 2: foreground refresh interval 연결**
**Step 3: home/menu bar에 상태 반영**
**Step 4: 중복 polling 방지 처리**

**Step 5: 검증**
- 수동 refresh + 자동 refresh 흐름 확인

**Step 6: Commit**
- `feat: add live polling service for foreground updates`

---

## Task 17: Widget/Activity 표시용 매퍼 작성

**Objective:** 도메인 모델을 Widget/Activity용 경량 뷰 데이터로 변환한다.

**Files:**
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Formatting/WidgetGameFormatter.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Formatting/ActivityGameFormatter.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Formatting/MenuBarFormatter.swift`

**Step 1: widget formatter 작성**
**Step 2: activity formatter 작성**
**Step 3: menu bar formatter 작성**
**Step 4: snapshot 테스트 추가**

**Step 5: 검증**
- 각 타깃에서 문자열 길이/정보량 확인

**Step 6: Commit**
- `feat: add formatters for widget activity and menu bar`

---

## Task 18: MVP 설정/즐겨찾기 최소 기능

**Objective:** 팀 즐겨찾기와 기본 표시 설정을 저장한다.

**Files:**
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/Favorites/`
- Create: `BaseballLiveKRApp/BaseballLiveKRiOS/Features/Settings/`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Domain/FavoriteTeam.swift`
- Create: `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Repository/PreferencesRepository.swift`

**Step 1: favorite team 저장 모델 작성**
**Step 2: SwiftData 또는 lightweight persistence 연결**
**Step 3: 홈 필터에 즐겨찾기 적용**
**Step 4: 메뉴바 우선 경기 선택에 반영**

**Step 5: 검증**
- 앱 재실행 후 즐겨찾기 유지 확인

**Step 6: Commit**
- `feat: add favorite team and basic preferences support`

---

## Task 19: 최소 검증 라운드

**Objective:** MVP 각 타깃의 가장 작은 의미 있는 검증을 수행한다.

**Files:**
- Modify: relevant tests/docs only if needed

**Step 1: Core tests 실행**
**Step 2: iOS target build 확인**
**Step 3: Widget target build 확인**
**Step 4: Live Activity target build 확인**
**Step 5: macOS target build 확인**
**Step 6: Preview/manual check 결과 기록**

**Step 7: Commit**
- `chore: validate MVP targets and core tests`

---

## Task 20: 문서 정리

**Objective:** 실제 구현 상태와 다음 단계 리스크를 문서화한다.

**Files:**
- Modify: `PROJECT_CONTEXT/current-status.md`
- Modify: `PROJECT_CONTEXT/roadmap.md`
- Modify: `README.md`

**Step 1: 구현된 범위 기록**
**Step 2: 미검증 항목 기록**
**Step 3: 실제 데이터 리스크 기록**
**Step 4: push/APNs 후속 계획 기록**

**Step 5: Commit**
- `docs: update status roadmap and MVP caveats`

---

## 추천 1차 실행 범위

초기 1주차에 가장 추천하는 범위:
- Task 1
- Task 2
- Task 3
- Task 4
- Task 5
- Task 6
- Task 7
- Task 8
- Task 9
- Task 10
- Task 11
- Task 12

즉,
- 실제 API 연결 전
- mock 기반으로 모든 핵심 표면을 먼저 만든다.

그 다음 2주차에:
- Task 13
- Task 14
- Task 15
- Task 16
- Task 17
- Task 18

---

## 현재 결론

가장 안전한 진행 순서는 다음과 같다.

1. 멀티타깃/공유 패키지 구조 생성
2. mock 기반 A/B UI 프로토타입 구현
3. UI 톤 결정
4. 데이터 소스 추상화
5. 공식 KBO 일정/게임 목록 연결
6. polling 기반 MVP 완성
7. 추후 Live Activity push/APNs 확장
