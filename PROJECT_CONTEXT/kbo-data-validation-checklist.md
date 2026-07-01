# KBO 데이터 검증 체크리스트

작성일: 2026-06-22
상태: Working v0.1
관련 Linear: KBO-27

## 1. 목적

실사용 UI 검증 전에 KBO 원천 응답과 backend normalized contract가 신뢰 가능한지 재현 가능한 명령으로 확인한다.

검증 대상:

- KBO 원천 `GetKboGameDate`, `GetKboGameList`, `GetScheduleList`, `TeamRankDaily`
- backend `/v1/games/today`가 사용하는 normalized month games
- backend `/v1/games/:gameId` 상세 lookup
- backend `/v1/standings` 순위/전적
- Swift DTO fixture contract 회귀 테스트

## 2. 빠른 실행

완료/예정 경기 날짜 1회 검증:

```bash
cd backend-spike
npm run validate:data -- --date 20260621 --write
```

현재 KBO 날짜 기준 검증:

```bash
cd backend-spike
npm run validate:data -- --write
```

생성물:

```text
backend-spike/artifacts/data-validation/<YYYYMMDD>/latest.json
```

## 3. 검증 항목

`validate:data`는 다음 항목을 확인한다.

- 요청 날짜가 backend 내부 KBO 날짜로 일관되게 정규화되는지
- normalized game ID가 중복되지 않는지
- 요청 날짜 raw game이 normalized requested-date game에 포함되는지
- 요청 날짜 schedule game이 normalized requested-date game에 포함되는지
- month-level normalized response가 requested-date games를 포함하는지
- status 값이 허용 enum 안에 있는지
- score가 음수가 아닌 정수인지
- live game에 inning/count/bases/current/recentPlay 중 하나 이상이 있는지
- scheduled game에 비정상 non-zero score가 있는지
- boxScore runs가 score와 일치하는지
- detail lookup이 첫 requested-date game ID를 다시 찾는지
- standings가 10개 팀을 반환하는지
- standings team ID가 중복되지 않는지
- standings가 requested-date game team을 커버하는지

## 4. 레벨 기준

- `fail`: contract mismatch 또는 앱이 잘못 표시할 수 있는 구조 오류
- `warn`: 원천 응답 특성상 발생 가능하지만 사람이 확인해야 하는 데이터 품질 이슈
- `pass`: 기대 조건 충족

스크립트는 `fail`이 하나라도 있으면 non-zero exit code를 반환한다. `warn`만 있으면 exit code는 0이다.

## 5. 함께 돌릴 회귀 명령

backend contract/type/test:

```bash
cd backend-spike
npm run typecheck
npm test
npm run build
```

Swift DTO/mapper contract:

```bash
cd Packages/BaseballLiveKRCore
swift test --disable-sandbox
```

Linux host에는 Swift toolchain이 없으므로 Swift 검증은 Mac-mini에서 실행한다.

## 6. Live 데이터 검증

경기 진행 중에는 polling fixture를 수집한다.

```bash
./scripts/run-kbo-live-fixture-capture.sh <YYYYMMDD>
```

수집물:

```text
backend-spike/logs/polling/<YYYYMMDD>/events.ndjson
backend-spike/logs/polling/<YYYYMMDD>/snapshots/*.normalized.json
backend-spike/fixtures/live-<YYYYMMDD>/latest-normalized.json
backend-spike/fixtures/live-<YYYYMMDD>/changes/*.json
```

live 경기에서 특히 보는 항목:

- status가 scheduled→live→final로 변하는지
- inning half/number가 정상인지
- B/S/O 값이 범위 안인지
- base occupancy가 실제 변화와 함께 바뀌는지
- current batter/pitcher가 공격/수비 팀과 일치하는지
- recentPlay가 source text 또는 fallback으로 의미 있게 채워지는지

## 7. 보존 정책

- raw source와 normalized JSON은 fixture 후보로 보존한다.
- 개인정보/비밀값은 포함하지 않는다.
- 날짜별 회귀 가치가 있는 dump만 `fixtures/`로 승격하고, 임시 실행 결과는 `artifacts/`에 둔다.
