# Liquid Glass + Toss Design System 적용 계획

작성일: 2026-06-16

## 1. 목표

Baseball LIVE KR의 iOS/macOS UI를 Apple Liquid Glass 계열의 플랫폼 네이티브 질감과 Toss식 명확한 정보 위계로 정리한다.

핵심 목표:

- Apple 플랫폼에서 자연스럽게 보이는 depth, material, toolbar, control 표현을 적용한다.
- Toss 제품처럼 빠르게 읽히는 정보 구조, 명확한 CTA, 낮은 인지 부하를 만든다.
- 야구 실시간성은 유지하되 화면 밀도를 제어해 경기 상황을 즉시 이해하게 한다.
- iOS 18/macOS 15 target에서도 안전하게 동작하도록 Liquid Glass API는 availability fallback을 둔다.

## 2. 기준 자료

Apple:

- Liquid Glass는 Apple 플랫폼 전반의 동적 material이며 glass의 광학적 속성과 fluidity를 결합한다.
- Apple HIG는 Liquid Glass를 content layer가 아니라 interactive element와 content를 구분하는 데 쓰라고 안내한다.
- SwiftUI는 standard component에서 Liquid Glass를 적용하고, custom component에는 glass effect/container 계열 API를 제공한다.

Toss:

- TDS는 Toss 제품군의 공통 디자인 언어이자 협업 기준이다.
- 공개 문서의 라이선스 범위는 App in Toss 사용으로 제한되므로 Baseball LIVE KR에 Toss UI Kit 자체를 복제하거나 asset을 가져오지 않는다.
- 적용 대상은 원칙과 UX 패턴이다: 빠른 이해, 일관성, 명확한 액션, 간결한 텍스트, 안정적인 spacing/typography.

참고 URL:

- https://developer.apple.com/documentation/technologyoverviews/liquid-glass
- https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views
- https://developer.apple.com/design/human-interface-guidelines/materials
- https://developer.apple.com/videos/play/wwdc2025/219/
- https://developers-apps-in-toss.toss.im/design/components.html

## 3. 적용 원칙

### 3.1 Liquid Glass 사용 범위

사용한다:

- macOS menu bar popover shell
- top command bar, settings sheet header, floating filters
- selected game detail header
- live status pill, my team summary, primary action button
- modal/sheet background와 elevated card 경계

사용하지 않는다:

- 경기 스코어 숫자 자체
- 긴 텍스트/표/일정 content layer 전체
- 작은 카드 5개가 한 줄에 놓이는 grid 전체
- 접근성 대비가 중요한 warning/error text

판단 기준:

- content보다 control이 앞에 나와야 하는가?
- glass를 제거해도 정보가 명확한가?
- 배경 복잡도 때문에 대비가 낮아지지 않는가?
- motion/refractive 느낌이 live 상태 이해를 방해하지 않는가?

### 3.2 Toss식 정보 구조

규칙:

- 화면마다 primary question을 하나로 둔다.
- 한 카드에는 한 핵심 상태만 강조한다.
- 숫자와 상태를 먼저 읽히게 하고 설명은 뒤로 보낸다.
- CTA는 한 화면에 primary 1개, secondary 1~2개만 둔다.
- 에러/빈 상태 문구는 짧게 쓰고 바로 해결 액션을 붙인다.

Baseball LIVE KR에 적용:

- 오늘 화면 primary question: "내 팀 경기가 지금 어떤 상태인가?"
- 리그 섹션 primary question: "오늘 전체 경기는 어떻게 진행 중인가?"
- 상세 화면 primary question: "이 경기에서 지금 무슨 일이 일어나고 있는가?"
- 설정 화면 primary question: "어느 backend 환경에 연결되어 있는가?"

## 4. 디자인 토큰 계획

현재 위치:

- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Tokens/`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Theme/`
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/`

추가/수정할 토큰:

- `KboSurfaceToken`
  - `contentBackground`
  - `card`
  - `elevated`
  - `glassControl`
  - `glassNavigation`
  - `criticalOverlay`
- `KboSemanticColorToken`
  - `accentBlue`
  - `success`
  - `warning`
  - `danger`
  - `neutralText`
  - `mutedText`
- `KboMotionToken`
  - `fastFeedback`
  - `sectionReveal`
  - `livePulse`
  - `scoreChange`
- `KboControlToken`
  - `primaryButtonHeight`
  - `compactButtonHeight`
  - `pillHeight`
  - `touchTargetMin`
- `KboGlassToken`
  - availability-safe glass style wrapper
  - fallback material/shadow/border style
  - card grouping rules

기존 토큰 조정:

- `KboColorToken`은 raw palette로 유지하고 semantic token을 위에 둔다.
- `KboTypographyToken`은 score와 label 위계를 더 명확히 분리한다.
- `KboSpacingToken`은 Toss식 4/8 grid를 유지하되 card 내부 compact density를 별도 token으로 둔다.

## 5. 컴포넌트 계획

새 컴포넌트:

- `KboGlassPanel`
  - Liquid Glass 사용 가능 OS에서는 glass effect 적용
  - 구 OS에서는 `.regularMaterial` 또는 현재 surface token fallback
- `KboCommandBar`
  - 날짜 이동, refresh, 설정, backend status를 담는 상단 control layer
- `KboStatusPill`
  - live/final/scheduled/delayed 상태를 동일 규칙으로 표시
- `KboPrimaryActionButton`
  - Toss식 단일 primary CTA
- `KboEmptyStateView`
  - "오늘은 경기가 없습니다."와 다음 경기 요약/action을 일관 처리
- `KboMetricRow`
  - 팀 순위/승무패/승률 등 짧은 metric 표시

기존 컴포넌트 개선:

- `ScoreDigitsView`
  - 숫자는 glass를 씌우지 않고 고대비 content로 유지
- `TeamBadgeView`
  - 팀 컬러는 유지하되 배경은 semantic surface로 분리
- `LiveBadgeView`
  - live pulse는 motion token으로 제어
- `BaseDiamondView`
  - detail screen에서만 강조하고 card grid에서는 compact mode 제공

## 6. 화면별 적용 계획

### 6.1 TodayGamesView

1차:

- 상단 header를 `KboCommandBar`로 분리
- 날짜 섹션 header는 glass가 아닌 flat semantic label로 유지
- 경기 card는 content 중심으로 두고 hover/selection에만 subtle glass/elevation 적용
- 빈 상태는 `KboEmptyStateView`로 통합

2차:

- "나의 팀" 섹션은 `KboGlassPanel`로 살짝 띄운다.
- 리그 전체 grid는 content layer로 두고 contrast와 density를 우선한다.
- live game card에는 score change animation만 적용한다.

### 6.2 GameDetailView

1차:

- detail hero header에 glass shell 적용
- score, inning, base diamond는 고대비 content로 유지
- 주요 액션은 primary/secondary button hierarchy 적용

2차:

- inning timeline 또는 recent play 영역은 Toss식 timeline/list pattern으로 정리
- raw backend/source meta는 debug disclosure로 접는다.

### 6.3 MenuBarDashboardView

1차:

- menu bar popover background를 glass shell로 정리
- backend status, refresh, settings controls를 command row로 정리
- "경기 없음" 상태는 Today view와 동일한 empty state copy 사용

2차:

- live game이 있을 때만 compact live pulse와 score transition 적용
- menu bar title은 짧은 score line 유지

### 6.4 Settings

1차:

- backend preset 선택 영역을 Toss식 list row로 정리
- 현재 연결 상태를 primary status card로 표시
- 환경변수 override 상태를 명확한 notice로 표시

2차:

- advanced/debug 설정은 접힌 섹션으로 이동
- URL 입력 오류는 즉시 validation copy로 표시

## 7. 구현 단계

### Phase 0: 디자인 audit

목표:

- 현재 화면별 card, button, label, empty state, status 표현을 inventory로 정리한다.

작업:

- Today, Detail, MenuBar, Settings screenshot 기준 audit
- 중복 style과 hardcoded color/spacing 목록화
- glass 적용 금지 영역 표시

완료 기준:

- `PROJECT_CONTEXT/design-audit.md` 작성
- 우선 적용 컴포넌트 5개 선정

### Phase 1: token foundation

목표:

- Apple/Toss 혼합을 직접 화면에 흩뿌리지 않고 design system token으로 감싼다.

작업:

- `KboSurfaceToken`, `KboSemanticColorToken`, `KboMotionToken`, `KboGlassToken` 추가
- Liquid Glass availability wrapper 작성
- 기존 `KboTheme`이 새 semantic token을 바라보도록 확장

완료 기준:

- iOS 18/macOS 15 fallback build 통과
- iOS 26/macOS 26 API는 `#available` 내부에만 존재

### Phase 2: component migration

목표:

- 화면 수정 전에 재사용 가능한 컴포넌트를 먼저 만든다.

작업:

- `KboGlassPanel`
- `KboCommandBar`
- `KboStatusPill`
- `KboPrimaryActionButton`
- `KboEmptyStateView`

완료 기준:

- 기존 화면에 끼워 넣어도 layout regression이 없는 상태
- snapshot 또는 view model 테스트 영향 없음

### Phase 3: Today/MenuBar 적용

목표:

- 사용 빈도가 가장 높은 화면부터 적용한다.

작업:

- Today header와 my team section 재구성
- league grid는 content-first 규칙으로 정리
- menu bar popover shell과 empty state 통일

완료 기준:

- 5경기 grid가 유지됨
- 두 자리 점수 layout 유지
- 경기 없음/예정/진행/종료 상태가 모두 명확히 표시됨

### Phase 4: Detail/Settings 적용

목표:

- 깊은 정보 화면과 운영 설정 화면의 hierarchy를 정리한다.

작업:

- Game detail hero/header glass 적용
- recent play/timeline 정리
- settings preset/status card 정리

완료 기준:

- backend preset 전환이 더 명확해짐
- detail screen에서 핵심 경기 상태가 first fold 안에 들어옴

### Phase 5: accessibility/performance hardening

목표:

- glass와 motion이 정보를 방해하지 않게 한다.

현재 fallback 정책:

- `KboGlassPanel`은 `KboGlassToken`을 통해 material, tint, border, shadow 값을 중앙 관리한다.
- Reduce Transparency가 켜진 환경에서는 glass material/tint 대신 style별 opaque surface를 사용한다.
- Reduce Motion이 켜진 환경에서는 `KboStatusPill`의 live pulse animation을 실행하지 않는다.
- 점수, 긴 텍스트, grid content layer에는 glass를 직접 씌우지 않고 content contrast를 우선한다.

작업:

- Reduce Transparency fallback
- Reduce Motion fallback
- high contrast mode 검증
- macOS popover blur/rendering 성능 확인
- Dynamic Type에서 card overflow 확인

완료 기준:

- accessibility setting별 fallback 명시
- iOS/macOS build 통과
- 실제 경기 데이터에서 주요 상태 회귀 없음

## 8. 리스크와 결정 필요 사항

리스크:

- Liquid Glass API는 OS availability가 높아 현재 deployment target에서 직접 사용하면 build/runtime 문제가 생길 수 있다.
- Toss TDS asset/component 자체 사용은 라이선스 범위 밖일 수 있다.
- glass를 card grid 전체에 쓰면 경기 정보 대비와 성능이 나빠질 수 있다.
- 현재 dark sports dashboard 정체성과 Toss식 밝고 간결한 패턴이 충돌할 수 있다.

결정 필요:

- Baseball LIVE KR의 기본 모드는 dark sports dashboard 유지 여부
- production build target을 iOS 26/macOS 26으로 올릴 시점
- staging/production backend preset의 실제 URL
- screenshot regression 도입 여부

## 9. 다음 실행 후보

우선순위:

1. `KboGlassToken`과 fallback wrapper 추가
2. `KboStatusPill`, `KboEmptyStateView`부터 컴포넌트화
3. Today header를 `KboCommandBar`로 분리
4. MenuBar popover shell에 glass/fallback 적용
5. Detail hero header redesign

첫 PR 권장 범위:

- design token foundation
- `KboGlassPanel`
- `KboStatusPill`
- Today/MenuBar에서 status pill만 교체

첫 PR에서 하지 않을 것:

- 전체 화면 redesign
- app icon Liquid Glass 대응
- 실제 Toss UI Kit 복제
- deployment target 상향
