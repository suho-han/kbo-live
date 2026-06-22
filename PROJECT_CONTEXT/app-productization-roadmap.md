# 앱 제품화 UX와 개인화 로드맵

작성일: 2026-06-20
상태: Working v0.1
관련 Linear: KBO-15

## 1. 목적

MVP는 경기 목록, 상세, 메뉴바, Widget, Live Activity의 기술 기반을 확인했다. 다음 단계는 실제 사용자가 매일 켜는 야구 동반 앱으로 만들기 위한 정보 구조와 개인화 우선순위를 정하는 것이다.

제품화 개발 순서는 macOS를 먼저 완료하고 iOS로 넘어간다. iOS 실제 기기 검증은 마지막에 수행한다. 먼저 macOS, shared SwiftUI feature, backend contract, 문서 기준을 정리한다.

## 2. 현재 구현 상태

이미 있는 제품 표면:

- Today 화면: 응원팀 선택, 나의 팀 요약, 대표 경기, 리그 전체 경기 목록.
- 경기 상세: scheduled/live/final/cancelled/unknown 상태별 주요 섹션 분기.
- 설정: backend preset, 응원팀 선택, 업데이트 확인.
- macOS Menu Bar: 응원팀 또는 첫 경기 요약, backend 상태 확인, 설정/메인 창 진입.
- Widget/Live Activity: projection 모델과 preview 구조.

현재 UX gap:

- 나의 팀 중심 홈의 우선순위 규칙이 문서화되어 있지 않다.
- 상세 화면의 상태별 fallback 규칙이 코드에는 있으나 제품 기준으로 고정되어 있지 않다.
- 메뉴바 quick action의 다음 단계가 정의되어 있지 않다.
- 알림 정책은 후보만 있고 발송 기준/빈도/개인화 범위가 없다.
- accessibility, empty/error/loading state 점검 기준이 MVP 체크리스트 수준에 머물러 있다.

## 3. 정보 구조 원칙

홈 화면 primary question:

- "내 팀 경기가 지금 어떻게 되고 있나?"

상세 화면 primary question:

- scheduled: "언제, 어디서, 누가 선발인가?"
- live: "현재 점수, 이닝, 주자, 타석 상황은 무엇인가?"
- final: "최종 결과와 핵심 기록은 무엇인가?"
- delayed/cancelled: "왜 정상 진행이 아닌가, 다음 행동은 무엇인가?"

메뉴바 primary question:

- "앱을 열지 않고도 내 팀 또는 대표 경기 상태를 알 수 있는가?"

Widget/Live Activity primary question:

- "잠금 화면/홈 화면에서 glanceable하게 상태만 볼 수 있는가?"

## 4. 나의 팀 중심 홈 우선순위

정렬 기준:

1. 사용자가 선택한 응원팀 경기.
2. 진행 중 경기.
3. 곧 시작하는 경기.
4. 종료된 경기.
5. 취소/지연 경기.

나의 팀 섹션:

- 선택된 팀이 있으면 팀 전적/순위와 해당 경기 카드를 항상 우선 표시한다.
- 선택된 팀 경기가 없는 날은 "오늘은 응원팀 경기가 없습니다" 상태를 표시하고 리그 전체로 자연스럽게 이어진다.
- 선택된 팀이 없으면 응원팀 선택 CTA를 유지한다.

리그 전체 섹션:

- 진행 중 경기를 우선 노출하되, 사용자가 선택한 필터를 명시적으로 존중한다.
- 경기가 없는 날짜는 empty state를 카드 하나로 표시한다.

## 5. 경기 상세 fallback 규칙

scheduled:

- 선발 투수가 있으면 선발 매치업을 강조한다.
- 팀 기록이 있으면 최근 흐름 대신 순위/승패를 표시한다.
- 분석 문구가 없으면 경기 시간, 구장, 선발 중심으로 축소한다.

live:

- count/base/current가 있으면 라이브 경기장 섹션을 우선한다.
- recentPlay가 있으면 별도 카드로 보여준다.
- recentPlay가 없으면 현재 타자/투수/주자 상태로 충분히 읽히게 한다.

final:

- boxScore/linescore가 있으면 최종 전광판을 확장한다.
- 승패 투수 정보가 없으면 score와 teamRecords만 표시한다.

delayed/cancelled/unknown:

- 점수보다 상태와 예정 시간/구장을 우선한다.
- 사용자가 오해하지 않도록 live action은 숨긴다.

## 6. 메뉴바 고도화

1차:

- 현재 backend 상태, 설정, 메인 창 진입을 유지한다.
- 응원팀 경기 카드가 있으면 항상 응원팀을 우선한다.
- 응원팀 경기가 없으면 리그 대표 경기 하나를 fallback으로 표시한다.

2차:

- 메뉴바에서 경기 상세 직접 열기.
- 메뉴바에서 응원팀 변경 shortcut.
- backend 상태 실패 시 설정 진입 CTA 강조.
- 마지막 갱신 시각과 수동 새로고침 affordance 강화.

## 7. 알림 설정 UI와 dedupe 정책

P1 목표는 push/APNs 구현 전에 응원팀 기반 local/app-level 알림 범위를 고정하는 것이다. 알림은 기본 opt-in이며, 응원팀이 없으면 설정 화면에서 비활성 상태와 응원팀 선택 CTA를 먼저 보여준다.

설정 UI 초안:

- 설정 > 응원팀 아래에 "알림" 섹션을 둔다.
- 상단 summary는 "응원팀 경기만 알림"을 기본 설명으로 사용한다.
- master toggle: "응원팀 경기 알림".
- 세부 toggle: "경기 시작", "득점", "실점", "경기 종료", "지연/취소".
- 경기 시작 offset은 첫 버전에서 고정 10분 전으로 두고, 사용자 선택 UI는 추가하지 않는다.
- backend 연결이 불안정하면 "상태 갱신이 늦을 수 있습니다" 보조 문구를 표시한다.

알림 후보:

- 경기 시작 10분 전.
- 응원팀 경기 시작.
- 응원팀 득점.
- 응원팀 실점.
- 경기 종료.
- 선발 변경 또는 지연/취소.

초기 범위:

- 응원팀 선택 없이는 알림을 기본 비활성화한다.
- push/APNs 전환 전에는 앱 실행 중 local notification 또는 앱 내 badge 수준으로 제한한다.
- 앱이 종료된 상태에서 background delivery를 보장하지 않는다.
- polling 기반에서는 실시간성을 과장하지 않고 "상태 갱신" 또는 "확인됨" 수준 copy를 쓴다.
- 선발 변경 알림은 source 안정성이 확인될 때까지 후보로만 유지한다.

Dedupe 기준:

- 경기 시작: `gameId + scheduledStartTime + notificationType`.
- 득점/실점: `gameId + awayScore + homeScore + halfInning + notificationType`.
- 경기 종료: `gameId + finalScore + notificationType`.
- 지연/취소: `gameId + status.rawValue + notificationType`.
- 같은 dedupe key는 같은 앱 실행 세션과 persisted notification ledger에서 한 번만 발송한다.

문구 원칙:

- 경기 시작: "곧 시작합니다"처럼 예정성을 유지한다.
- 득점/실점: "상태가 갱신됐습니다"를 보조 문구로 사용해 polling 지연 가능성을 드러낸다.
- 종료: "경기가 종료됐습니다"와 최종 score를 함께 표시한다.
- 지연/취소: 원천 상태 문구가 불확실하면 "경기 상태가 변경됐습니다"로 fallback한다.

## 8. Accessibility와 상태 점검

필수 점검:

- Dynamic Type 또는 app font scale에서 주요 카드가 잘리지 않는다.
- 색상만으로 live/final/scheduled를 구분하지 않는다.
- loading/error/empty state가 Today, Detail, Menu Bar에서 모두 존재한다.
- Reduce Motion에서는 과한 transition을 제거한다.
- Reduce Transparency에서는 glass surface fallback을 사용한다.
- 버튼 label은 VoiceOver에서 행동이 드러나야 한다.

## 9. 1차 제품화 Milestone 분해

제품화 실행 순서:

1. macOS 앱을 먼저 완료한다.
2. macOS 메뉴바, 메인 창, packaged backend, 원격 Mac-mini smoke, 스크린샷 검증을 완료 기준으로 둔다.
3. macOS 완료 후 iOS Widget/Live Activity 실제 기기 검증으로 넘어간다.

P0:

- 나의 팀 홈 fallback copy 확정.
- 상세 화면 상태별 fallback rule을 regression checklist에 반영.
- 메뉴바 응원팀 우선 표시와 backend 실패 CTA 점검.

P1:

- 알림 설정 UI 초안.
- 알림 dedupe key와 polling 기반 제한사항 문서화.
- 경기 상세 진입 경로를 메뉴바에서 직접 연결.

P2:

- 선수/팀 기록 DB 연동 후 상세 화면 enrich.
- Widget 개인화.
- Live Activity 실제 기기 검증 후 제품 copy 조정.

## 10. 완료 기준

KBO-15는 다음 기준을 만족하면 완료로 본다.

- 홈/상세/메뉴바/위젯 UX 우선순위가 문서화되어 있다.
- 상태별 화면 fallback 규칙이 문서화되어 있다.
- 알림 정책 후보와 초기 제한사항이 정리되어 있다.
- MVP 이후 1차 제품화 milestone이 P0/P1/P2로 분해되어 있다.
