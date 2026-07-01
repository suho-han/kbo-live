# KBO Data Source Research

작성일: 2026-06-10
상태: Research Note v0.1
검증 환경: `/home/suhohan/kbo-live` Linux shell에서 HTTP 호출 확인
목적: Baseball LIVE KR 앱의 초기 데이터 소스 및 실시간 공급 방식을 결정하기 위한 조사 메모

## 1. 결론 요약

현재 확인 기준으로 가장 현실적인 초기 방향은 다음과 같다.

### 추천안
- **1차 데이터 소스:** 공식 KBO 웹사이트의 AJAX 웹서비스 활용 검토
- **1차 공급 방식:** 앱이 직접 원천에 붙기보다, 중간에 **BFF/Backend**를 두고 polling + normalization 수행
- **앱 반영 방식:** MVP는 polling 기반, 이후 push/APNs 확장

### 이유
- 공식 KBO 사이트에서 실제 JSON 계열 응답을 주는 endpoint를 확인함
- 경기 목록/날짜/기본 상태 수준은 웹서비스에서 받을 가능성이 높음
- 다만 접근 헤더 제약/스키마 안정성/ToS/anti-bot 리스크가 있어 앱에서 직접 원천 접근하는 구조는 위험함
- 따라서 **서버에서 수집/정규화하고 앱은 안정된 JSON만 소비하는 구조**가 가장 안전함

---

## 2. 조사 방식

실제 확인한 것:
- `https://www.koreabaseball.com/` 공식 페이지 HTML
- `Schedule.aspx`, `GameCenter/Main.aspx` 내부 스크립트/호출 경로
- 실제 AJAX endpoint 직접 POST 호출
- Naver Sports / Daum Sports는 비교 후보로 최소 수준 탐색

주의:
- 본 문서는 공개 웹 응답 구조를 확인한 메모임
- 서비스 이용약관/상업적 사용 허용 여부는 별도 검토 필요
- 본 조사만으로 법적/운영적 사용 가능성이 확정되는 것은 아님

---

## 3. 공식 KBO 사이트에서 확인된 힌트

## 3.1 Schedule 페이지 내부 호출 경로 확인
`https://www.koreabaseball.com/Schedule/Schedule.aspx` HTML 내부에서 아래 웹서비스 호출 문자열을 확인했다.

확인된 경로:
- `/ws/Controls.asmx/GetYearList`
- `/ws/Controls.asmx/GetMonthList`
- `/ws/Schedule.asmx/GetScheduleList`
- `/ws/Schedule.asmx/GetMonthSchedule`
- `/ws/Main.asmx/GetKboGameDate`

즉, 공식 KBO 사이트는 적어도 일부 일정/날짜/월별 데이터에 대해 브라우저 AJAX 호출 기반으로 동작한다.

---

## 3.2 GameCenter 페이지 내부 호출 힌트
`https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx` 에서 아래 경로를 확인했다.

확인된 경로:
- `/ws/Main.asmx/GetKboGameDate`
- `/ws/Main.asmx/GetKboGameList`

이로부터 알 수 있는 점:
- GameCenter 진입용 경기 날짜/게임 목록은 AJAX로 가져옴
- 기본적인 당일 경기 목록, 경기 ID, 팀명, 구장, 선발 정보, 점수 상태 등을 가져올 가능성이 있음

---

## 4. 실제 호출로 검증된 endpoint

다음 endpoint는 브라우저 유사 헤더를 포함했을 때 실제 응답이 돌아오는 것을 확인했다.

### 공통적으로 넣어야 성공한 헤더
- `User-Agent: Mozilla/5.0`
- `X-Requested-With: XMLHttpRequest`
- `Content-Type: application/x-www-form-urlencoded; charset=UTF-8`
- `Referer: https://www.koreabaseball.com/...`
- `Origin: https://www.koreabaseball.com`
- `Accept: application/json, text/javascript, */*; q=0.01`

이 점 자체가 중요하다.
즉, **단순 서버-서버 호출이나 앱 직접 호출이 언제나 안정적으로 허용된다고 보기 어렵다.**

---

## 4.1 `GetKboGameDate`

Endpoint:
- `https://www.koreabaseball.com/ws/Main.asmx/GetKboGameDate`

전송 파라미터 예시:
- `leId=1`
- `srId=0,1,3,4,5,7,8,9`
- `date=20260610`

확인된 응답 예시:

```json
{
  "BEFORE_G_DT": "20260609",
  "NOW_G_DT": "20260610",
  "NOW_G_DT_TEXT": "2026.06.10(수)",
  "AFTER_G_DT": "20260611",
  "code": "100",
  "msg": "성공"
}
```

활용 가능성:
- 오늘/이전/다음 경기일 탐색
- date navigation
- 앱 첫 진입 기본 날짜 계산

---

## 4.2 `GetKboGameList`

Endpoint:
- `https://www.koreabaseball.com/ws/Main.asmx/GetKboGameList`

전송 파라미터 예시:
- `leId=1`
- `srId=0,1,3,4,5,7,8,9`
- `date=20260610`

확인된 응답 구조 예시 필드:
- `G_ID`
- `G_DT`
- `G_TM`
- `S_NM`
- `AWAY_ID`
- `HOME_ID`
- `AWAY_NM`
- `HOME_NM`
- `T_PIT_P_NM`
- `B_PIT_P_NM`
- `GAME_STATE_SC`
- `GAME_INN_NO`
- `GAME_TB_SC`
- `T_SCORE_CN`
- `B_SCORE_CN`
- `STRIKE_CN`
- `BALL_CN`
- `OUT_CN`
- `B1_BAT_ORDER_NO`
- `B2_BAT_ORDER_NO`
- `B3_BAT_ORDER_NO`
- `T_P_NM`
- `B_P_NM`
- `LINEUP_CK`
- `VOD_CK`

의미:
- 기본적으로 앱 메인 리스트/메뉴바/위젯에 필요한 정보 상당수가 여기서 올 수 있음
- live 상태일 때는 inning/count/bases/player 정보까지 담길 가능성이 있음
- 경기 상세의 최소 상단 요약 데이터 소스로 매우 유력함

---

## 4.3 `GetScheduleList`

Endpoint:
- `https://www.koreabaseball.com/ws/Schedule.asmx/GetScheduleList`

전송 파라미터 예시:
- `leId=1`
- `srIdList=0,9,6`
- `seasonId=2026`
- `gameMonth=06`
- `teamId=`

확인된 응답 특징:
- JSON 형태 응답
- `rows` 배열 포함
- 각 row 안에 HTML 문자열 포함
- 예: 경기 결과, 리뷰 링크, gameId 포함 anchor HTML

활용 가능성:
- 월간 일정/결과 화면
- gameId 확보
- 경기센터 링크 파생

주의:
- 이 응답은 **완전한 clean JSON domain model이 아니라 HTML fragment가 섞여 있음**
- 앱에서 직접 사용하기보다는 backend/parser에서 정규화하는 편이 안전

---

## 5. 발견된 장점

### 장점 1. 공식 출처
- KBO 공식 사이트가 원천에 가까움
- 팀명, 구장, 경기 ID, 선발, 상태 코드 등 정합성이 높을 가능성이 큼

### 장점 2. 실제 JSON 응답 확인
- 단순 HTML scraping만 필요한 게 아니라 endpoint 기반 접근 여지가 있음
- 일정/경기 목록은 구조화된 응답으로 접근 가능

### 장점 3. 앱 MVP에 필요한 기본 데이터 범위와 잘 맞음
- 홈 리스트
- 예정/종료/진행 상태
- 메뉴바 요약
- Widget 기본 표면

---

## 6. 발견된 리스크

### 리스크 1. 브라우저 유사 헤더 의존
브라우저와 비슷한 헤더를 넣지 않으면 endpoint가 에러 HTML을 반환했다.

의미:
- 원천이 비공식 server API로 설계된 것이 아닐 수 있음
- anti-bot / referer / request-shape 제약이 있을 수 있음
- 앱 직접 호출 안정성이 낮을 수 있음

### 리스크 2. 스키마 안정성 보장 없음
- `.asmx` endpoint는 공식 public developer API가 아님
- 필드명/코드값/응답 구조가 예고 없이 바뀔 수 있음

### 리스크 3. 상세 play-by-play 범위 미확정
현재 확인된 것은 주로:
- 날짜
- 경기 목록
- 일정 목록

아직 이번 조사만으로는 아래를 확정하지 못했다.
- pitch-by-pitch
- full play-by-play
- lineup detail endpoint
- inning linescore detail endpoint
- highlight/review structured endpoint

### 리스크 4. 이용약관/허용 범위 미검토
- 비공식 endpoint 소비는 법적/운영적 검토 필요
- 상용 배포 시 더 중요

---

## 7. 포털 소스(Naver/Daum) 비교 메모

이번 조사에서 Naver/Daum은 구조 탐색만 최소 수준으로 확인했다.

### Naver Sports
- 메인 HTML에서 바로 공개 API 경로를 쉽게 찾지 못함
- 응답 압축/클라이언트 렌더링/스크립트 로딩이 섞여 있음
- 추가 분석 가능하지만, 초기 소스로는 공식 KBO보다 설명력이 약함

### Daum Sports
- 페이지 HTML은 확인 가능
- 공개 API 흔적을 즉시 찾지 못함
- 구조 분석은 더 가능하지만, 이번 단계에서는 우선순위 낮음

### 판단
초기 단계에서는:
- **공식 KBO source를 우선 조사/연결**
- Naver/Daum은 fallback 또는 보조 검증 소스로 검토

---

## 8. 앱 직접 호출 vs BFF/Backend

## 8.1 앱 직접 호출
장점:
- 서버 없이 빠르게 MVP 시연 가능
- 구조가 단순해 보임

단점:
- 헤더 제약 대응이 취약
- endpoint 변경 시 앱 업데이트 필요
- widget/live activity/macOS가 각각 원천에 붙을 가능성 생김
- rate limit / 차단 / 구조 변경 대응이 어려움
- App Review / 운영 안정성 관점에서 불리

### 결론
**권장하지 않음.**
테스트 스파이크 용도로만 사용 가능.

---

## 8.2 BFF/Backend 경유
장점:
- 원천 호출 로직을 서버 한 곳에서 관리 가능
- 응답 정규화 가능
- polling 주기 제어 가능
- 캐시 가능
- 앱은 안정된 JSON만 소비하면 됨
- 이후 APNs/live push 연결이 쉬워짐

단점:
- 서버 운영 필요
- 초기 구현량 증가

### 결론
**가장 권장.**
실제 앱 구조와 확장성을 고려하면 서버 중간 계층이 맞다.

---

## 9. 추천 공급 방식

## Phase 1 — MVP
- backend가 공식 KBO endpoint polling
- 15~30초 주기로 경기 상태 수집
- 앱/iOS/macOS/widget은 backend API 사용
- Live Activity는 앱 foreground update 중심

## Phase 2
- backend가 상태 diff 계산
- 이벤트 단위 변화 추출
  - 득점
  - 이닝 변경
  - 아웃 증가
  - 경기 종료
  - 역전

## Phase 3
- APNs로 Live Activity push update
- 앱 background 제약 우회
- lock screen 실시간성 개선

---

## 10. 서버가 제공해야 할 내부 정규화 모델

앱에 바로 줄 내부 API 예시:

```json
{
  "gameId": "20260610SKLG0",
  "status": "live",
  "venue": "잠실",
  "startTime": "2026-06-10T18:30:00+09:00",
  "awayTeam": { "id": "SK", "name": "SSG" },
  "homeTeam": { "id": "LG", "name": "LG" },
  "score": { "away": 3, "home": 2 },
  "inning": { "number": 7, "half": "bottom" },
  "count": { "balls": 2, "strikes": 1, "outs": 2 },
  "bases": { "first": true, "second": false, "third": true },
  "current": {
    "batter": "오스틴",
    "pitcher": "정철원"
  },
  "recentPlay": "좌전 적시타"
}
```

의도:
- 앱 타깃이 원천 필드명에 직접 결합되지 않게 함
- widget/activity/menu bar가 모두 같은 모델을 읽게 함

---

## 11. 추천 백엔드 스택

가장 현실적인 초안:

### 옵션 A
- TypeScript
- Hono 또는 Fastify
- 간단한 in-memory cache 또는 Redis

### 옵션 B
- Python
- FastAPI
- scheduler/caching 조합

현재 앱과 별도 개발성을 생각하면 TypeScript 쪽이 운영하기 무난하다.

---

## 12. 지금 바로 해야 할 기술 검증

다음 스파이크를 권장한다.

### Spike 1
공식 KBO endpoint 3종을 backend script로 래핑
- `GetKboGameDate`
- `GetKboGameList`
- `GetScheduleList`

검증 포인트:
- 헤더 없을 때 실패 여부
- 헤더 포함 시 성공 여부
- 응답 필드 안정성
- 경기 진행 중 필드 변화 여부

### Spike 2
당일 live 경기 시간대에 15초 polling
검증 포인트:
- inning/count/bases/current player 필드가 실제 변하는지
- 응답 지연/실패 빈도
- 차단 여부

### Spike 3
정규화 API 초안 작성
검증 포인트:
- iOS home/widget/live activity에 필요한 데이터가 충분한지
- 추가 play-by-play source가 필요한지

---

## 13. 현재 추천 결론

현재 기준 최적 전략:

1. **공식 KBO 웹서비스를 1차 원천 후보로 채택**
2. **앱이 직접 호출하지 말고 backend/BFF를 둔다**
3. **MVP는 polling 기반으로 시작한다**
4. **실시간성 요구가 커지면 diff + APNs로 확장한다**
5. **상세 play-by-play는 추가 endpoint 조사 또는 보조 source 검토가 필요하다**

한 줄로 정리하면:

> 초기 MVP는 `공식 KBO 웹서비스 + 중간 backend + polling` 조합이 가장 현실적이다.
