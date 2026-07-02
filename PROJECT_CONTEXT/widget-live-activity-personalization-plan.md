# Widget/Live Activity 개인화 검증 계획

작성일: 2026-06-22
상태: Working v0.1
관련 Linear: KBO-22, KBO-9, KBO-15

## 1. 목적

Widget과 Live Activity를 실제 기기 검증 전에 제품 기준으로 분리한다. 이 문서는 응원팀 개인화, shared projection contract, preview/sample state, 검증 범위를 고정한다.

KBO-9는 실제 iPhone에서 Live Activity start/stop과 Lock Screen/Dynamic Island 동작을 검증하는 작업이다. KBO-22는 그 전에 확인할 Widget/Live Activity 개인화 기준과 preview contract를 정리하는 작업이다.

## 2. 구현 위치

### Widget

Widget extension의 홈 화면 위젯은 다음 파일에 있다.

- `BaseballLiveKRApp/Widget/BaseballLiveKRWidgetBundle.swift`
  - Widget extension entry point.
  - `TodayGameWidget()`과 `LiveGameActivityWidget()`을 함께 등록한다.
- `BaseballLiveKRApp/Widget/TodayGameWidget.swift`
  - 홈 화면/잠금 화면용 Today widget UI.
  - 현재 `StaticConfiguration` + `TodayGameProvider` 구조다.
  - 현재 preview/timeline은 `SampleGameFactory.widgetSnapshot`을 사용한다.
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Projections/WidgetGameSnapshot.swift`
  - Widget에 넘기는 축약 projection 모델.
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/WidgetGameSnapshotMapper.swift`
  - full `Game`에서 `WidgetGameSnapshot`으로 줄이는 mapper.

### Live Activity

Live Activity는 Widget extension 안의 ActivityKit widget과 iOS app의 controller가 나뉘어 있다.

- `BaseballLiveKRApp/Widget/LiveGameActivityWidget.swift`
  - Lock Screen, Dynamic Island compact/minimal/expanded UI.
  - `ActivityConfiguration(for: LiveGameActivityAttributes.self)`가 실제 ActivityKit UI entry point다.
- `BaseballLiveKRApp/Shared/LiveGameActivityAttributes.swift`
  - iOS app과 Widget extension이 공유하는 Activity attributes/content state.
  - content state는 `ActivityGameState`만 들고 간다.
- `BaseballLiveKRApp/Shared/LiveGameActivityController.swift`
  - iOS app 쪽 start/stop/update/end 제어.
  - 진행 중 경기만 시작 가능하게 제한한다.
- `BaseballLiveKRApp/Shared/BaseballLiveKRHomeRootView.swift`
  - Today 화면에서 `LiveGameActivityController`를 만들고 live activity toggle을 연결한다.
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Projections/ActivityGameState.swift`
  - Live Activity에 전달하는 축약 content state.
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/ActivityGameStateMapper.swift`
  - full `Game`에서 `ActivityGameState`로 줄이는 mapper.

## 3. 현재 contract

### WidgetGameSnapshot

현재 Widget projection은 다음 필드를 가진다.

- `gameId`
- `awayTeamName`, `homeTeamName`
- `awayScore`, `homeScore`
- `status`
- `inningText`
- `baseState`
- `recentPlay`

현재 한계:

- 응원팀 ID 또는 응원팀 기준 home/away 여부가 없다.
- Widget title/copy가 “대표 경기” 중심이다.
- 선택 팀이 경기에 없을 때 보여줄 fallback reason이 없다.

### ActivityGameState

현재 Live Activity content state는 다음 필드를 가진다.

- `awayScore`, `homeScore`
- `status`
- `inningText`
- `outs`
- `hasRunnerOnFirst`, `hasRunnerOnSecond`, `hasRunnerOnThird`
- `shortRecentPlay`

Attributes는 다음 고정값을 가진다.

- `gameID`
- `awayTeamName`
- `homeTeamName`

현재 한계:

- Live Activity는 이미 특정 live game에서 시작되므로 “응원팀 선택”은 시작 후보 선택 단계의 문제다.
- Activity payload에는 full `Game`을 넘기지 않는 원칙이 지켜지고 있다.
- 개인화 copy는 content state가 아니라 start 대상 선정과 UI 문구에서 처리해야 한다.

## 4. 개인화 기준

### Widget 개인화 우선순위

Widget은 앱을 열지 않아도 사용자의 응원팀 상태를 보여주는 표면이다. 대표 경기보다 응원팀을 우선한다.

1. 선택한 응원팀 경기가 있으면 그 경기를 표시한다.
2. 응원팀 경기가 진행 중이면 live 상태, 점수, 이닝, 최근 플레이를 우선한다.
3. 응원팀 경기가 예정이면 시작 시간, 구장, 선발 후보를 우선한다.
4. 응원팀 경기가 종료됐으면 최종 score와 핵심 결과를 우선한다.
5. 선택 팀 경기가 없으면 “오늘은 응원팀 경기가 없습니다” fallback을 표시하고 리그 대표 경기 하나를 보조로 둔다.
6. 응원팀 미선택이면 응원팀 선택 CTA 성격의 copy를 표시한다.

### Live Activity 개인화 우선순위

Live Activity는 사용자가 명시적으로 시작한 live game을 추적한다.

1. Today 화면에서 응원팀 경기가 live이면 해당 카드에 start action을 우선 노출한다.
2. 응원팀 경기 외 리그 live game도 시작 가능하지만, 응원팀 카드보다 낮은 우선순위다.
3. Activity UI에는 “응원팀”이라는 설정 상태를 과하게 표시하지 않는다. 점수/이닝/주자/최근 플레이가 우선이다.
4. 경기가 live가 아니게 되면 기존 KBO-9 기준처럼 update cycle에서 종료한다.
5. remote push update는 MVP 범위 밖이다. 앱 실행 중 local update만 기대한다.

## 5. Preview/sample state 기준

실기기 검증 전 preview/sample은 최소 다음 케이스를 가져야 한다.

### Widget preview 후보

- 응원팀 live game: 점수, 이닝, 주자, 최근 플레이 표시.
- 응원팀 scheduled game: `vs`, 시작 시간, 구장 중심 표시.
- 응원팀 final game: 최종 score와 종료 상태 표시.
- 응원팀 경기 없음: fallback copy 표시.
- 응원팀 미선택: 선택 CTA 성격의 fallback copy 표시.

### Live Activity preview 후보

- Lock Screen live: 점수 + 이닝 + 최근 플레이.
- Dynamic Island expanded: 양 팀명과 score, 이닝이 잘리지 않는지 확인.
- Dynamic Island compact: away/home score가 최소 정보로 읽히는지 확인.
- Dynamic Island minimal: `KBO` 또는 팀/상태 축약값이 과도하게 길지 않은지 확인.
- final/delayed로 바뀐 content state: 앱 update cycle에서 종료되어야 하므로 장시간 표시 UI를 만들지 않는다.

## 6. KBO-9와 중복되지 않는 검증 범위

KBO-22에서 할 일:

- projection contract가 full `Game` 없이 충분한지 확인.
- 개인화 우선순위와 fallback copy를 문서화.
- preview/sample state를 보강할 후보 정의.
- 실제 기기 전 빌드 가능성과 target 연결 상태 확인.

KBO-9에서 할 일:

- 실제 iPhone에서 Live Activity 시작/종료 확인.
- Lock Screen 표시 확인.
- Dynamic Island compact/minimal/expanded 표시 확인.
- ActivityKit 권한 거부/기기 설정 케이스 확인.

## 7. 다음 구현 후보

1. `WidgetGameSnapshot`에 개인화 display metadata를 추가한다.
   - 예: `headline`, `contextText`, `isFavoriteTeamGame`, `fallbackKind`.
2. `TodayGameWidgetView`를 score-only 카드에서 상태별 glance card로 확장한다.
3. `SampleGameFactory`에 Widget/Live Activity preview 케이스를 명시적으로 추가한다.
4. `ActivityGameState`는 당장은 확장하지 않는다. Live Activity payload를 작게 유지한다.
5. Widget 실제 데이터 공급 방식은 App Group/shared storage 설계 후 별도 작업으로 분리한다.

## 8. 완료 기준

- Widget과 Live Activity의 파일 위치와 책임이 문서화되어 있다.
- Widget 개인화와 Live Activity 개인화 범위가 분리되어 있다.
- KBO-9 실기기 검증 항목과 KBO-22 사전 contract 검증 항목이 중복되지 않는다.
- 다음 구현 후보가 commit 단위로 나뉘어 있다.
