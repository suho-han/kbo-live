# KBO Live App Initial Plan

작성일: 2026-06-10
상태: Draft v0.2
개발 환경: 로컬 Mac 개발 예정

업데이트 메모 (2026-06-10):
- Apple Sports를 참고하되 KBO 특화 scoreboard-first 방향으로 초기 제품 결정을 구체화
- 언어/프레임워크/패키지 선택에서 MVP 기준 기본값과 제외 후보를 명시
- iPhone / Widget / Live Activity / macOS Menu Bar 간 데이터 흐름과 역할 분리를 더 명확히 정리

## 1. 목표

KBO 경기를 Apple 플랫폼에서 실시간으로 확인할 수 있는 앱을 설계한다.

핵심 경험:
- iPhone에서 경기 진행 상황을 빠르게 확인
- Live Activity / Dynamic Island로 실시간 경기 상태 노출
- Widget으로 홈 화면에서 즉시 점수 확인
- macOS 상단 메뉴바(Menu Bar)에서 경기 스코어와 상태를 지속적으로 확인

제품 한 줄 정의:

> KBO 중계 감성과 전광판 UI를 Apple 네이티브 경험으로 옮긴 실시간 스코어 앱

---

## 2. 플랫폼 범위

### 1차 대상 플랫폼
- iPhone app
- iPhone Widget
- iPhone Live Activity / Dynamic Island
- macOS Menu Bar app

### 제외 / 후순위
- iPad 전용 최적화
- watchOS
- tvOS
- Android
- 웹 클라이언트

---

## 3. 기술 스택 초안

### 클라이언트
- Language: Swift 6
- UI: SwiftUI
- Widget: WidgetKit
- Live Activity: ActivityKit
- macOS Menu Bar: MenuBarExtra
- Persistence: SwiftData
- Networking: URLSession + async/await
- Notifications: UserNotifications
- Logging: OSLog

### 선택 패키지
- 이미지 캐싱 필요 시: Nuke

### 아키텍처
- 초기: MVVM + Observation
- 공용 로직은 shared domain/service 계층으로 분리

### 권장 프로젝트 구조
- iOS App target
- Widget Extension target
- Live Activity target
- macOS App target
- Shared Core module/package

### 현재 권장 기본값 (결론)
- **언어**: Swift 6 유지
- **UI**: 전면 SwiftUI
- **아키텍처**: MVVM + Observation + AppContainer 조합
- **공유 로직 위치**: `Packages/BaseballLiveKRCore`
- **공통 UI 위치**: `Packages/BaseballLiveKRDesignSystem`
- **데이터 공급**: 초기엔 `backend-spike` 같은 BFF를 표준 공급원으로 간주
- **실시간 전략**: MVP는 polling, 이후 APNs Live Activity push 확장
- **저장소 역할**: SwiftData는 즐겨찾기/설정/최근 선택 저장 위주, live game source of truth로는 쓰지 않음

### MVP에서 굳이 넣지 않을 것
- TCA/ReactorKit 같은 무거운 상태관리 프레임워크
- Alamofire/Moya 같은 별도 네트워킹 추상화
- Realm/CoreData 기반 복잡한 오프라인 우선 구조
- 서버 없이 클라이언트가 KBO 원천 endpoint를 직접 장시간 polling하는 구조

### 패키지/프레임워크 선택 가이드
- **필수**
  - SwiftUI
  - WidgetKit
  - ActivityKit
  - OSLog
  - URLSession
- **선택**
  - Nuke: 팀 로고/원격 이미지 캐싱이 실제로 필요할 때만 추가
- **보류**
  - Combine 전면 도입: async/await + Observation으로 먼저 시작
  - Tuist/XcodeGen: 타깃 수가 더 커진 뒤 재검토

---

## 4. 디자인 방향

Apple Sports를 직접 따라가기보다, KBO 팬 관점의 화면 감성과 경기 인지 속도를 우선한다.

### 핵심 디자인 키워드
- KBO team-centric
- scoreboard-first
- broadcast-like
- stadium atmosphere
- compact but emotional
- dark-first

### Apple Sports에서 가져올 것 / 가져오지 않을 것
**가져올 것**
- 한눈에 읽히는 hierarchy
- 팀/점수/상태를 최우선으로 두는 정보 밀도
- Lock Screen / Widget / compact surface에서의 극단적 요약
- 과한 장식보다 상태 인지 속도를 우선하는 레이아웃

**그대로 복제하지 않을 것**
- 지나치게 미국 스포츠 앱 같은 neutral 톤
- KBO 팀 감성을 약하게 만드는 과도한 미니멀리즘
- 야구 특유의 주자/아웃/최근 플레이 정보를 희생하는 지나친 단순화

**KBO 쪽으로 더 밀어붙일 것**
- 주자 상태와 아웃 상태를 항상 빠르게 읽히게 만들기
- 팀 컬러 accent를 더 적극적으로 사용
- 최근 플레이/타자-투수 문맥을 Apple Sports보다 조금 더 드러내기

### 시각 방향
- 다크 모드 중심
- 야간 경기 / 전광판 / 중계 UI 감성
- 중립 배경 + 팀 컬러 accent
- 점수 / 회차 / 아웃 / 주자 상태를 가장 빠르게 읽을 수 있게 설계

### 정보 우선순위
1. 팀명 / 점수
2. 회차(초/말) / 아웃 / 주자 상태
3. 최근 플레이
4. 타자 / 투수 매치업
5. 선발 / 라인업 / 부가 기록

---

## 5. UI 톤 실험 계획

초기에는 아래 2개 톤을 모두 테스트한 뒤 최종 선택한다.

### Tone A: 전광판 스타일
특징:
- 점수 숫자가 크다
- 회차 / 아웃 / 주자 상태가 즉시 보인다
- 패널 / 격자 느낌이 강하다
- Widget / Menu Bar / Live Activity에 유리하다

적합 화면:
- 홈 경기 카드
- 위젯
- Live Activity
- 메뉴바 기본 표시

### Tone B: 방송 중계 스타일
특징:
- TV 중계 하단 scoreboard 감성
- 한 줄 정보 밀도가 높다
- 최근 플레이 / 타자-투수 흐름을 설명하기 쉽다
- 경기 상세 헤더에 적합하다

적합 화면:
- 경기 상세 상단
- Live Activity Expanded
- 메뉴바 드롭다운
- 카드 하단 상태 영역

### 현재 가설
- 전체 골격은 Tone A(전광판)
- 상세 설명 영역은 Tone B(방송 중계) 혼합

즉:
- Home / Widget / Menu Bar / Dynamic Island Compact → Tone A 우선
- Detail Header / Recent Play / Dropdown → Tone B 혼합 검토

### 테스트 우선 화면
1. Home 경기 카드 A/B
2. 경기 상세 상단 헤더 A/B
3. Small Widget A/B
4. Live Activity Lock Screen A/B

### 판단 기준
- 0.5초 내 현재 경기 상황 인지 가능 여부
- 점수 / 회차 / 주자 상태 가독성
- KBO 감성 전달력
- 작은 영역에서의 정보 손실 정도

---

## 6. 화면별 와이어프레임 텍스트 초안

## 6.1 iPhone Home

목적:
- 오늘 경기 전체를 빠르게 훑기
- 진행 중 경기 우선 확인
- 즐겨찾기 팀 경기 빠른 진입

### 헤더
```text
┌─────────────────────────────────────┐
│ KBO Live                            │
│ 6월 10일 수요일                     │
│ [진행 중] [전체] [즐겨찾기] [종료]  │
└─────────────────────────────────────┘
```

### 경기 카드 A (전광판 스타일)
```text
┌─────────────────────────────────────┐
│ LIVE                         7회말  │
│ ─ team color accent line ───────── │
│                                     │
│   LG                       3        │
│   두산                     2        │
│                                     │
│   2아웃   ●  ○  ●                  │
│   최근: 오스틴 적시타              │
│                                     │
│   [상세]                  [★]       │
└─────────────────────────────────────┘
```

### 경기 카드 B (방송 중계 스타일)
```text
┌─────────────────────────────────────┐
│ LIVE                                │
│ LG  3  :  2  두산                   │
│ 7회말 · 2아웃 · 1,3루               │
│ 타자 오스틴 vs 투수 정철원          │
│ 최근: 좌전 적시타                   │
│                            [상세][★]│
└─────────────────────────────────────┘
```

### 예정 경기 카드
```text
┌─────────────────────────────────────┐
│ 18:30 예정                          │
│ KIA                    vs        롯데│
│ 선발: 네일                    반즈   │
│ 구장: 광주                          │
│                            [알림][★]│
└─────────────────────────────────────┘
```

### 종료 경기 카드
```text
┌─────────────────────────────────────┐
│ FINAL                               │
│ 한화                     6          │
│ SSG                      4          │
│ 승: 김서현 / 패: 노경은 / 세: 박상원│
│                            [리뷰][★]│
└─────────────────────────────────────┘
```

---

## 6.2 iPhone 경기 상세

목적:
- 지금 경기 장면을 가장 명확히 전달
- 점수 외에도 경기 흐름 파악 가능해야 함

### 상세 헤더 A
```text
┌─────────────────────────────────────┐
│ [←] LG vs 두산                 [★]  │
│                                     │
│ LG                       3          │
│ 두산                     2          │
│                                     │
│ 7회말 · 2아웃 · 1,3루               │
│ 볼 2 · 스트라이크 1                 │
│                                     │
│ [ Live Activity 시작 ]              │
└─────────────────────────────────────┘
```

### 상세 헤더 B
```text
┌─────────────────────────────────────┐
│ [←] 잠실야구장                 LIVE │
│ LG 3 : 2 두산                       │
│ 7회말 · 2사 · 1,3루                 │
│ 타석: 오스틴 / 투수: 정철원         │
│ 최근: 좌전 안타로 1득점             │
│ [ Live Activity 시작 ]              │
└─────────────────────────────────────┘
```

### 이닝별 점수표
```text
┌─────────────────────────────────────┐
│        1 2 3 4 5 6 7 8 9   R H E    │
│ LG     0 1 0 0 0 1 1 - -   3 8 0    │
│ 두산   0 0 0 1 0 1 - - -   2 7 1    │
└─────────────────────────────────────┘
```

### 현재 상황
```text
┌─────────────────────────────────────┐
│ 현재 상황                           │
│ 타자: 오스틴                        │
│ 투수: 정철원                        │
│ 카운트: 2-1                         │
│                                     │
│           ○                         │
│        ○     ●                      │
│           ○                         │
│                                     │
│ 아웃: ● ● ○                         │
└─────────────────────────────────────┘
```

### 최근 플레이
```text
┌─────────────────────────────────────┐
│ 최근 플레이                         │
│ 7회말 오스틴 좌전 안타, 1타점       │
│ 7회말 박해민 볼넷                   │
│ 7회말 홍창기 우익수 뜬공            │
│ 7회말 신민재 희생번트               │
│                           [전체보기]│
└─────────────────────────────────────┘
```

---

## 6.3 즐겨찾기 팀 화면

```text
┌─────────────────────────────────────┐
│ LG 트윈스                      [★]  │
│ 오늘 경기                           │
│                                     │
│ LG 3 : 2 두산                       │
│ 7회말 · 2아웃 · 1,3루               │
│                                     │
│ 다음 경기                           │
│ 6/11 18:30 vs 두산                  │
│                                     │
│ 최근 결과                           │
│ 승 / 패 / 승 / 승 / 패              │
└─────────────────────────────────────┘
```

---

## 6.4 Small Widget

### Small A
```text
┌───────────────┐
│ LIVE     7말  │
│ LG      3     │
│ 두산    2     │
│ 2아웃          │
│ ● ○ ●         │
└───────────────┘
```

### Small B
```text
┌───────────────┐
│ LG 3:2 두산   │
│ 7회말 · 2사   │
│ 1,3루         │
│ 적시타        │
└───────────────┘
```

권장:
- Small Widget은 전광판형 우선 검토

---

## 6.5 Medium Widget

### Medium A
```text
┌─────────────────────────────┐
│ LIVE                  7회말 │
│ LG                 3        │
│ 두산               2        │
│ 2아웃 · 1,3루               │
│ 최근: 오스틴 적시타         │
│─────────────────────────────│
│ KIA vs 롯데   18:30 예정    │
└─────────────────────────────┘
```

### Medium B
```text
┌─────────────────────────────┐
│ LG 3:2 두산                 │
│ 7회말 · 2사 · 1,3루         │
│ 타자 오스틴 / 투수 정철원   │
│ 최근: 좌전 적시타           │
│─────────────────────────────│
│ 다음 경기: KIA vs 롯데      │
└─────────────────────────────┘
```

---

## 6.6 Live Activity

### Lock Screen A
```text
┌─────────────────────────────────────┐
│ LG                          3       │
│ 두산                        2       │
│                                     │
│ 7회말 · 2아웃                       │
│ 주자: 1,3루                         │
│ 최근: 오스틴 적시타                 │
└─────────────────────────────────────┘
```

### Lock Screen B
```text
┌─────────────────────────────────────┐
│ LG 3 : 2 두산                       │
│ 7회말 · 2사 · 1,3루                 │
│ 타석: 오스틴                        │
│ 최근: 좌전 적시타로 1득점           │
└─────────────────────────────────────┘
```

### Dynamic Island Compact
```text
[ LG 3:2 두산 | 7말 ]
```

### Dynamic Island Expanded A
```text
┌─────────────────────────────┐
│ LG 3 : 2 두산               │
│ 7회말 · 2아웃               │
│ ● ○ ●                       │
│ 최근: 적시타                │
└─────────────────────────────┘
```

### Dynamic Island Expanded B
```text
┌─────────────────────────────┐
│ LG 3 : 2 두산               │
│ 타자 오스틴 / 정철원        │
│ 7회말 · 2사 · 1,3루         │
│ 최근: 좌전 안타 1타점       │
└─────────────────────────────┘
```

---

## 6.7 macOS Menu Bar

### 메뉴바 기본 표시
```text
LG 3:2 두산 7말
```

대안:
```text
LG 3-2 두산 ●○● 2사
```

권장:
- 메뉴바 기본 텍스트는 길이 제한 때문에 `LG 3:2 두산 7말` 형태 우선

### 드롭다운
```text
┌─────────────────────────────────────┐
│ KBO Live                            │
│─────────────────────────────────────│
│ LIVE                                │
│ LG 3 : 2 두산     7회말 · 2사 · 1,3루│
│ 최근: 오스틴 적시타                 │
│                                     │
│ SSG 1 : 1 한화     5회초 · 1사 · 주자없음│
│ 최근: 삼진                         │
│─────────────────────────────────────│
│ 예정 경기                           │
│ KIA vs 롯데       18:30             │
│ 삼성 vs NC        18:30             │
│─────────────────────────────────────│
│ [즐겨찾기 관리] [설정]              │
└─────────────────────────────────────┘
```

---

## 7. 데이터 및 실시간 업데이트 전략

## 초기 MVP
- 앱 foreground에서 15~30초 polling
- 위젯은 timeline 기반 제한적 갱신
- Live Activity는 앱 활성 시 local update 중심

## 이후 확장
- 서버에서 경기 상태 diff 계산
- 중요 이벤트만 푸시
  - 득점
  - 이닝 종료
  - 경기 종료
  - 역전
- APNs 기반 Live Activity push update 도입 검토

### 판단
진짜 Apple Sports 급 실시간성은 서버 + push 설계가 필요함.
MVP는 polling 기반으로 시작하고, 데이터 안정화 뒤 push로 확장하는 것이 현실적임.

---

## 8. 데이터 소스 전략

권장:
- 초기부터 BFF/Backend를 표준 경로로 두는 쪽이 낫다
- 앱/위젯/라이브액티비티/macOS가 모두 같은 normalized contract를 소비해야 한다

백엔드 역할:
- 원천 데이터 수집
- 스코어 상태 정규화
- polling / diff 계산
- 캐시
- push 트리거

후보 기술:
- TypeScript + Hono/Fastify
- 또는 Python + FastAPI

### 권장 데이터 흐름
```text
KBO source
→ backend-spike / future BFF
→ normalized JSON contract
→ BaseballLiveKRCore DTO
→ domain Game
→ target-specific projection
   ├─ WidgetGameSnapshot
   ├─ ActivityGameState
   └─ MenuBarGameSummary
→ each UI surface
```

### 타깃별 역할 분리
- iPhone app
  - 전체 경기 목록, 상세, 즐겨찾기, 수동 refresh, Live Activity 시작 진입점
- Widget
  - 가장 짧은 snapshot 중심, 무거운 상태 표현 금지
- Live Activity
  - 점수/회차/아웃/주자/짧은 최근 플레이만 유지
- macOS Menu Bar
  - 초압축 한 줄 상태 + 드롭다운에서 보조 정보 확장

---

## 9. MVP 우선순위

### Phase 1
- iPhone 경기 리스트
- 경기 상세
- 즐겨찾기
- Small / Medium widget
- macOS 메뉴바 기본 ticker
- polling 기반 실시간 갱신

### Phase 2
- Live Activity
- Dynamic Island
- 최근 플레이 반영
- 주요 경기 이벤트 알림

### Phase 3
- 서버 캐시 / 정규화
- APNs 기반 실시간 업데이트

### Phase 4
- 사용자 설정
  - 표시 팀 선택
  - 메뉴바 고정 경기
  - spoiler 방지
  - 업데이트 빈도 조절

---

## 10. 로컬 Mac 개발 전제

이 프로젝트는 로컬 Mac에서 개발할 예정이므로, 초기 개발 환경은 아래를 전제로 한다.

- Xcode 최신 안정 버전 사용
- iPhone Simulator + macOS target 동시 개발
- Apple Developer 기능(Live Activity, Widget) 테스트 가능 환경 확보
- 메뉴바 앱과 iPhone 앱을 같은 워크스페이스에서 관리

개발 초기에 가장 먼저 확인할 것:
1. Xcode 프로젝트 멀티타깃 구조 생성
2. iOS / Widget / macOS target 간 shared module 연결 방식
3. Live Activity sample 동작 확인
4. MenuBarExtra sample 동작 확인

---

## 11. 다음 액션 제안

우선순위 추천:
1. SwiftUI 컴포넌트 구조 설계
2. Xcode 프로젝트 구조 설계
3. 화면별 A/B 프로토타입 스펙 작성
4. MVP 구현 태스크 분해

가장 추천하는 바로 다음 단계:

> Home 카드 / Detail 헤더 / Small Widget / Live Activity 4개 화면의 A/B 디자인 스펙을 먼저 고정하고, 그 다음 Xcode 프로젝트 구조를 만든다.

---

## 12. 현재 결론

- 기술 스택은 Apple 네이티브가 적합
- 디자인은 Apple Sports 직접 모방보다 KBO 감성에 맞춰야 함
- UI 톤은 전광판 스타일과 방송 중계 스타일을 모두 테스트한 뒤 선택
- MVP는 iPhone + Widget + macOS Menu Bar 중심으로 시작
- 로컬 Mac 개발을 기준으로 Xcode 멀티타깃 구조 설계가 필요
