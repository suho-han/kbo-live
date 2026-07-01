# Baseball LIVE KR Backend Spike Results

작성일: 2026-06-10
업데이트: 2026-06-14
상태: Working v0.2

## 1. 목적

KBO 공식 웹서비스를 직접 앱에서 때리지 않고, 중간 backend/BFF를 둘 수 있는지 검증한 결과를 요약한다.

---

## 2. 구현 완료 범위

구현 위치:
- `backend-spike/`

구현된 API:
- `GET /health`
- `GET /games/today?date=YYYY-MM-DD`
- `GET /games/:gameId?date=YYYY-MM-DD`
- `GET /debug/source/today?date=YYYY-MM-DD`

구현된 내부 요소:
- KBO client
- 브라우저 유사 headers
- raw DTO schema
- normalized game mapper
- monthly schedule metadata mapper
- month-level schedule + game merge
- polling script
- dump script
- smoke / fixture / live / route tests

---

## 3. 실제 검증 결과

실행 확인:
- `npm install` 성공
- `npm run typecheck` 성공
- `npm run build` 성공
- `npm run test` 성공
- `/health` 응답 성공
- `/games/today?date=2026-06-14` 응답 성공

실제 확인된 점:
- 2026-06-10 기준 5경기 normalized 응답 반환 확인
- 2026-06-14 요청에서 6월 전체 schedule 기준 90경기 로드 확인
- 날짜별 `GetKboGameList` 응답과 월별 `GetKboGameSchedule` 응답을 병합해 종료/예정/진행 경기를 함께 반환
- scheduled 경기에서 기본 score/status/venue/startTime 필드 확인
- schedule metadata 기준 `broadcastChannels`, `homepageLinks`, `venue`, `startTime` 보강 확인
- `startTime` normalized 형식은 현재 `YYYYMMDDTHH:mm:ss+09:00` (예: `20260610T18:30:00+09:00`) 확인
- KBO source 오류는 `KboSourceError`로 감싸 route 계층에서 처리 가능
- polling script 2회 실행 시
  - 첫 tick: `initial snapshot`
  - 둘째 tick: `changedGames: 0`
- fixture/log 저장 경로 정상 생성 확인

현재 fixture 기준:
- `backend-spike/fixtures/202606-completed/<YYYYMMDD>/latest.json`
- 2026-06-02 ~ 2026-06-07
- 2026-06-09 ~ 2026-06-13
- `backend-spike/logs/polling/<YYYYMMDD>/events.ndjson`

---

## 4. 현재 normalized 모델에서 확인된 필드

현재 앱용으로 다룰 수 있는 필드:
- `gameId`
- `date`
- `venue`
- `startTime`
- `status`
- `awayTeam`
- `homeTeam`
- `score`
- `inning`
- `count`
- `bases`
- `current`
- `probablePitchers`
- `broadcastChannels`
- `pitcherDecisions`
- `teamRecords`
- `homepageLinks`
- `sourceMeta`

아직 약한 필드:
- `recentPlay`
- `current.batter`
- `current.pitcher`
- `boxScore`
- `lineupPreview`
- `analysis`

이유:
- 경기 전 데이터에서는 빈 문자열이 들어올 수 있음
- 실제 live 경기 시점 검증이 더 필요함

---

## 5. 남은 리스크

### 1) live 경기 시점 검증 미완료
아직 실제 진행 중 경기에서 아래 변화가 충분히 검증되지 않았다.
- inning
- count
- bases
- current
- recentPlay

### 2) 공식 endpoint 장기 안정성
- 브라우저 유사 헤더 요구 가능성 있음
- 장기 polling 시 차단/rate limit 여부 미확정

### 3) 상세 API 계약 미완성
- `/games/:gameId`는 현재 month-level list filter 수준
- 추후 상세 linescore / play-by-play source 탐색 필요 가능성 있음

---

## 6. 다음 단계 추천

1. 실제 경기 시간대 polling 10~20분 수집
2. collected fixture 기준으로 mapper 보정
3. shared Swift DTO/domain 계약 확정
4. Widget / Live Activity projection 모델 설계
5. iOS/macOS mock 화면 연결

---

## 7. 현재 결론

backend-spike는 **초기 구조 결정용으로 충분히 유효**하다.

특히 아래 판단은 이미 가능한 상태다.
- 앱이 직접 KBO source를 치지 않고 backend를 두는 구조가 타당함
- Swift app은 normalized JSON 계약을 기준으로 shared DTO를 설계하는 것이 안전함
- 실제 제품 개발은 이제 Swift/Xcode 쪽으로 넘어가되, live 데이터 검증은 계속 backend-spike로 병행하는 방식이 적합함

---

## 8. 2026-06-16 실데이터 보강 구현 상태

구현됨:
- `TeamRankDaily.aspx?date=YYYYMMDD` HTML을 backend-spike에서 조회/파싱해 당일 팀 순위, 승패무, 승률, 승차, 최근 10경기, 연속 기록을 `teamRecords`로 보강한다.
- KBO game list raw field의 승/패/세이브 투수명을 `pitcherDecisions`로 정규화한다.
- Swift DTO/domain/mapper가 `broadcastChannels`, `homepageLinks`, `pitcherDecisions`를 수신하고 Today/Game Detail 화면에서 중계 채널과 승패 투수를 간단히 노출한다.

아직 남음:
- 포털 보조 source는 아직 붙이지 않았다. 공식 KBO 원천에서 부족한 `boxScore`, `lineupPreview`, `analysis`, 상세 play-by-play 후보 source를 별도 조사/구현해야 한다.
- `TeamRankDaily` HTML 구조 변경 시 parser 보정이 필요할 수 있다.
