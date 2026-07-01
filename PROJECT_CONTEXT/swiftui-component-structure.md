# Baseball LIVE KR SwiftUI Component Structure

작성일: 2026-06-10
상태: Draft v0.1
개발 환경: 로컬 Mac + SwiftUI Preview 중심

## 1. 목표

Baseball LIVE KR의 화면을 SwiftUI 컴포넌트 단위로 나누고, 전광판 스타일(Tone A)과 방송 중계 스타일(Tone B)을 빠르게 비교할 수 있는 구조를 정의한다.

핵심 원칙:
- 정보 우선순위가 UI 계층에도 그대로 반영되어야 함
- KBO 특화 표현(점수, 회차, 아웃, 주자, 최근 플레이)을 primitive로 승격
- 카드/헤더 A/B 테스트가 가능하도록 variant 구조 채택
- Widget/Live Activity/macOS Menu Bar에서 재사용 가능한 최소 표현 컴포넌트를 만든다

---

## 2. 컴포넌트 레이어

권장 레이어는 4단계다.

### Layer 1. Tokens
- color
- spacing
- corner radius
- typography
- shadow/glow

### Layer 2. Primitives
- badge
- divider
- score digit
- team mark
- inning chip
- out dots
- base diamond

### Layer 3. Composite Components
- scoreboard row
- game status strip
- recent play ticker
- matchup line
- inning linescore table

### Layer 4. Screens / Feature Containers
- home card
- detail header
- widget views
- live activity layouts
- menu bar dropdown rows

---

## 3. 디자인 토큰 구조

권장 타입:

```text
BaseballLiveKRDesignSystem/
├── Tokens/
│   ├── KboColorToken.swift
│   ├── KboSpacingToken.swift
│   ├── KboTypographyToken.swift
│   ├── KboRadiusToken.swift
│   └── KboShadowToken.swift
```

### 컬러 토큰 예시
- `backgroundPrimary`
- `backgroundSecondary`
- `surfaceCard`
- `surfaceElevated`
- `borderMuted`
- `textPrimary`
- `textSecondary`
- `statusLive`
- `statusFinal`
- `statusDelayed`

### 팀 컬러 맵 예시
- `lgTwinsPrimary`
- `doosanBearsPrimary`
- `kiaTigersPrimary`
- `lotteGiantsPrimary`
- `ssgLandersPrimary`
- `hanwhaEaglesPrimary`
- `ncDinosPrimary`
- `ktWizPrimary`
- `samsungLionsPrimary`
- `kiwoomHeroesPrimary`

---

## 4. Primitive 컴포넌트

## 4.1 TeamBadgeView
목적:
- 팀 약어/엠블럼/컬러를 일관되게 표현

입력:
- team name
- short name
- logo
- accent color
- emphasis state

용도:
- 홈 카드
- 상세 헤더
- 메뉴바 드롭다운
- widget

---

## 4.2 ScoreDigitsView
목적:
- 큰 숫자 점수 표현

표현 모드:
- scoreboardLarge
- scoreboardCompact
- menuBarCompact

주의:
- 숫자 width를 안정적으로 유지
- score 갱신 시 transition 최소 적용

---

## 4.3 LiveBadgeView
목적:
- LIVE / FINAL / 예정 / 지연 상태 표현

변형:
- live pulse badge
- final neutral badge
- delayed yellow badge
- scheduled muted badge

---

## 4.4 InningStateView
목적:
- `7회초`, `7회말`, `종료`, `18:30 예정` 같은 핵심 상태 요약

입력:
- game status
- inning no
- top/bottom
- start time
- delay status

---

## 4.5 OutCountView
목적:
- 아웃 카운트 0~2를 점/원으로 즉시 인지

표현:
- `● ● ○`
- 또는 세 개의 원형 인디케이터

필수 조건:
- 작은 사이즈에서도 읽혀야 함

---

## 4.6 BaseDiamondView
목적:
- 1/2/3루 점유 상태를 가장 직관적으로 표현

입력:
- first occupied
- second occupied
- third occupied

용도:
- 홈 카드
- 상세 헤더
- widget
- live activity
- menu bar dropdown

이 컴포넌트는 Baseball LIVE KR의 핵심 primitive 중 하나다.

---

## 4.7 PitchCountView
목적:
- 볼/스트라이크를 짧게 표현

표현 예시:
- `B 2 · S 1`
- `2-1`

초기 MVP에서는 상세 화면 위주 사용

---

## 4.8 RecentPlayTickerView
목적:
- 최근 이벤트 1줄 표현

예시:
- `오스틴 적시타`
- `삼진`
- `투수 교체`
- `우천 지연`

주의:
- 홈 카드에서는 한 줄로 truncate
- 상세에서는 2~4줄 리스트와 연결

---

## 5. Composite 컴포넌트

## 5.1 ScoreboardRowView
목적:
- 팀명 + 점수 한 줄 표현

구성:
- TeamBadgeView
- ScoreDigitsView
- optional ranking/status marker

용도:
- 홈 카드
- 상세 헤더
- live activity
- widget

---

## 5.2 GameStatusStripView
목적:
- 회차 + 아웃 + 주자 상태를 한 줄로 압축

예시:
- `7회말 · 2아웃 · 1,3루`
- `18:30 예정 · 잠실`
- `종료 · 승 김서현 / 세 박상원`

하위 구성:
- InningStateView
- OutCountView 또는 text summary
- BaseDiamondView 또는 text base summary

---

## 5.3 MatchupLineView
목적:
- 타자 vs 투수 정보 표시

예시:
- `타자 오스틴 vs 투수 정철원`
- `선발 네일 vs 반즈`

용도:
- 홈 카드 B형
- 상세 헤더
- medium widget
- live activity expanded

---

## 5.4 LinescoreTableView
목적:
- 이닝별 점수표 표시

구성:
- inning header row
- away row
- home row
- R/H/E summary columns

주의:
- 상세 화면 전용
- widget/live activity에는 직접 재사용하지 않음

---

## 5.5 GameMetaFooterView
목적:
- 구장 / 방송 / 승패투수 / 리뷰 액션 등 보조 정보 표현

용도:
- 예정 경기 카드
- 종료 경기 카드
- 상세 하단 메타 영역

---

## 6. A/B 테스트를 위한 Variant 구조

권장 방식:
- 공통 primitive/composite는 공유
- 최종 조립 뷰만 A/B로 분기

예시:

```text
Components/
├── HomeGameCardA.swift
├── HomeGameCardB.swift
├── GameDetailHeaderA.swift
├── GameDetailHeaderB.swift
├── SmallWidgetA.swift
├── SmallWidgetB.swift
├── LockScreenLiveActivityA.swift
└── LockScreenLiveActivityB.swift
```

### 원칙
A/B 차이는:
- 정보 배치
- 텍스트 설명량
- 여백 밀도
- 강조 위치

공유해야 하는 것:
- 팀명/점수 데이터
- 상태 포맷터
- 색상 토큰
- primitive

---

## 7. 화면별 컴포넌트 트리

## 7.1 Home 화면

```text
HomeView
├── HomeHeaderView
├── HomeFilterBar
├── LiveGamesSection
│   ├── HomeGameCardA or B
│   │   ├── LiveBadgeView
│   │   ├── ScoreboardRowGroup
│   │   │   ├── ScoreboardRowView (away)
│   │   │   └── ScoreboardRowView (home)
│   │   ├── GameStatusStripView
│   │   ├── MatchupLineView (optional)
│   │   ├── RecentPlayTickerView
│   │   └── FavoriteButton
├── ScheduledGamesSection
│   └── ScheduledGameCardView
└── FinalGamesSection
    └── FinalGameCardView
```

---

## 7.2 경기 상세 화면

```text
GameDetailView
├── GameDetailHeaderA or B
│   ├── ScoreboardRowGroup
│   ├── GameStatusStripView
│   ├── PitchCountView
│   ├── BaseDiamondView
│   ├── MatchupLineView
│   └── LiveActivityActionButton
├── LinescoreTableView
├── CurrentSituationCard
│   ├── BatterPitcherInfoView
│   ├── PitchCountView
│   ├── BaseDiamondView
│   └── OutCountView
├── RecentPlayListView
├── MatchupSummaryCard
└── GameMetaFooterView
```

---

## 7.3 Small Widget

```text
SmallGameWidgetViewA or B
├── LiveBadgeView or CompactHeader
├── ScoreboardRowGroupCompact
├── InningStateView
├── OutCountView
└── BaseDiamondView or TextSummary
```

추천:
- A형 전광판 우선

---

## 7.4 Medium Widget

```text
MediumGameWidgetViewA or B
├── PrimaryGameCardCompact
│   ├── ScoreboardRowGroup
│   ├── GameStatusStripView
│   ├── MatchupLineView (optional)
│   └── RecentPlayTickerView
└── SecondaryGameSummaryRow
```

---

## 7.5 Live Activity

```text
LockScreenGameViewA or B
├── ScoreboardRowGroup
├── GameStatusStripView
├── BaseDiamondView or BaseTextSummary
├── MatchupLineView (optional)
└── RecentPlayTickerView
```

```text
DynamicIslandCompactView
└── CompactGameTickerView
```

```text
DynamicIslandExpandedView
├── ScoreboardRowGroupCompact
├── GameStatusStripView
├── MatchupLineView
└── RecentPlayTickerView
```

---

## 7.6 macOS Menu Bar

```text
MenuBarRootView
├── MenuBarLabelView
│   └── CompactGameTickerView
└── MenuBarDropdownView
    ├── LiveGamesList
    │   └── MenuBarGameRow
    │       ├── ScoreboardRowCompact
    │       ├── GameStatusStripView
    │       └── RecentPlayTickerView
    ├── ScheduledGamesList
    └── SettingsActionsView
```

---

## 8. 공통 ViewModel / Presenter 구조

SwiftUI view는 최대한 표시 전용으로 두고, 표시용 모델을 분리한다.

권장 타입:
- `GameCardViewData`
- `GameHeaderViewData`
- `WidgetGameViewData`
- `ActivityGameViewData`
- `MenuBarGameViewData`

### 이유
- 원본 도메인 모델을 그대로 뷰에 넘기면 분기 로직이 늘어남
- 타깃별 제약에 맞춘 경량 포맷이 필요함
- Preview/mock 작성이 쉬워짐

---

## 9. 상태별 표현 규칙

## LIVE
- 빨간/주황 계열 badge
- 최근 플레이 노출
- score emphasis 강함
- subtle pulse 허용

## 예정
- 시작 시간 강조
- 선발 정보 노출 가능
- 주자/아웃 UI 비활성

## 종료
- 점수는 유지하되 mute tone
- 승/패/세 정보 추가 가능
- recent play 대신 결과 메타 노출

## 지연/취소
- 노란 badge
- 이유 텍스트 우선
- time update 가능 시 표시

---

## 10. Preview 세트 권장안

로컬 Mac 개발에서 Preview 세트를 미리 만든다.

필수 preview case:
1. 예정 경기
2. 1점 차 LIVE 경기
3. 득점 직후 LIVE 경기
4. 9회말 2사 만루 긴장 상황
5. 종료 경기
6. 우천 지연 경기

이 preview가 있으면:
- Home 카드 비교
- Widget 비교
- Live Activity 비교
- Menu bar row 비교
를 빠르게 반복 가능

---

## 11. 초기 구현 우선 컴포넌트

가장 먼저 만들 컴포넌트 순서:

1. `TeamBadgeView`
2. `ScoreDigitsView`
3. `LiveBadgeView`
4. `OutCountView`
5. `BaseDiamondView`
6. `RecentPlayTickerView`
7. `ScoreboardRowView`
8. `GameStatusStripView`
9. `HomeGameCardA`
10. `HomeGameCardB`
11. `GameDetailHeaderA`
12. `GameDetailHeaderB`

### 이유
이 순서면 A/B 테스트에 필요한 핵심 UI를 가장 빨리 볼 수 있다.

---

## 12. 현재 추천 결론

- SwiftUI 컴포넌트는 primitive 중심으로 설계해야 재사용성이 높다
- `BaseDiamondView`, `OutCountView`, `ScoreDigitsView`는 제품 정체성을 만드는 핵심이다
- A/B 테스트는 primitive 공유 + 조립 레벨 분기로 처리하는 것이 가장 효율적이다
- 로컬 Mac 개발에서는 Preview와 mock 데이터 세트가 실제 생산성을 좌우한다
