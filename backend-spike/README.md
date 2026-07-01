# Baseball LIVE KR Backend Spike

Fastify 기반 Baseball LIVE KR backend spike 뼈대입니다.

## 목적
- 공식 KBO 웹서비스 호출 검증
- raw 응답 → 앱용 normalized JSON 변환 실험
- polling 기반 실시간 상태 변화 확인
- fixture/log 수집으로 live 필드 매핑 검증 준비

## 실행

```bash
npm install
npm run dev
```

진행 중 경기 UI 테스트용 단일 live fixture를 반환하려면:

```bash
KBO_USE_TEST_LIVE_GAME=1 npm run dev
```

이 모드에서 `/games/today`는 실제 KBO source를 호출하지 않고 `status: "live"` 경기 1개를 반환합니다.

운영 전환 준비용 cache 환경변수:

```bash
KBO_CACHE_TTL_GAME_IDLE_SEC=60
KBO_CACHE_TTL_GAME_LIVE_SEC=5
KBO_CACHE_STALE_IF_ERROR_SEC=600
```

`/games/today`와 `/v1/games/today`는 같은 날짜 요청을 짧게 cache하고, 동일 date에 대한 동시 요청은 하나의 KBO source 요청으로 deduplicate합니다. source 오류가 발생해도 stale window 안의 cache가 있으면 stale 응답을 반환합니다.

DB foundation 환경변수:

```bash
BASEBALL_LIVE_KR_DB_PATH=.data/baseball-live-kr.sqlite
BASEBALL_LIVE_KR_DB_DISABLED=1
BASEBALL_LIVE_KR_DB_ENABLED=1
```

기본값은 `backend-spike/.data/baseball-live-kr.sqlite`입니다. KBO source 응답은 `raw_sources` table에 checksum 기준으로 중복 저장을 방지하며 기록됩니다. 테스트 환경에서는 기본 비활성화되며, 임시 실행에서 DB 기록을 끄려면 `BASEBALL_LIVE_KR_DB_DISABLED=1`, 테스트에서 명시적으로 켜려면 `BASEBALL_LIVE_KR_DB_ENABLED=1`을 사용합니다.

## 검증

```bash
npm test
npm run typecheck
```

`npm test`에는 실제 KBO endpoint를 호출하는 live smoke 테스트가 포함됩니다. 기본 검증 날짜는 테스트 설정의 `TEST_DATE`이며, 다른 날짜를 보려면 아래처럼 지정합니다.

```bash
TEST_DATE=YYYYMMDD npm test
```

## 주요 엔드포인트
- `GET /health`
- `GET /ready`
- `GET /v1/health`
- `GET /v1/ready`
- `GET /games/today?date=YYYY-MM-DD`
- `GET /games/:gameId?date=YYYY-MM-DD`
- `GET /v1/games/today?date=YYYY-MM-DD`
- `GET /v1/games/:gameId?date=YYYY-MM-DD`
- `GET /standings?date=YYYY-MM-DD`
- `GET /v1/standings?date=YYYY-MM-DD`
- `GET /v1/teams/standings?date=YYYY-MM-DD`
- `GET /v1/players/search?q=NAME&season=YYYY`
- `GET /v1/players/:playerId/season?season=YYYY&date=YYYYMMDD`
- `GET /debug/source/today?date=YYYY-MM-DD`

## 스크립트

### 1) polling 로그 + snapshot 저장
```bash
npm run poll -- --date 2026-06-10 --interval 15 --iterations 20 --save-raw
```

생성물:
- `logs/polling/<date>/events.ndjson`
- `logs/polling/<date>/snapshots/*.normalized.json`
- `logs/polling/<date>/snapshots/*.raw.json` (`--save-raw` 사용 시)
- `fixtures/<date>/latest-normalized.json`
- `fixtures/<date>/latest-raw.json` (`--save-raw` 사용 시)
- `fixtures/<date>/changes/*.json` (변화가 있을 때만)

옵션:
- `--interval <sec>`: polling 간격
- `--iterations <n>`: n회 실행 후 종료 (`0`이면 계속 실행)
- `--logs-dir <path>`: 로그 출력 경로 override
- `--fixtures-dir <path>`: fixture 출력 경로 override
- `--save-raw`: raw source snapshot도 저장
- `--no-save-snapshots`: per-tick snapshot 파일 저장 비활성화
- `--no-capture-on-change`: change fixture 저장 비활성화

repo root wrapper:

```bash
../scripts/run-kbo-live-fixture-capture.sh 20260616
```

기본값:
- 30초 간격
- 480회 실행
- raw snapshot 저장
- `fixtures/live-<YYYYMMDD>/`에 최신 fixture 저장

### 2) 원천 응답 단건 dump + fixture 저장
```bash
npm run dump -- --date 2026-06-10 --write
```

생성물:
- `fixtures/<date>/dump/latest.json`
- `fixtures/<date>/dump/<timestamp>.json`

옵션:
- `--out-dir <path>`: dump 저장 경로 override
- `--write`: stdout 출력과 함께 fixture 파일 저장

### 3) 2026년 6월 완료 경기 raw dump

완료 경기 검증용 raw dump는 날짜별로 저장합니다.

```bash
npm run dump -- --date 2026-06-13 --write --out-dir fixtures/202606-completed/20260613
```

현재 저장 기준:
- `fixtures/202606-completed/<YYYYMMDD>/latest.json`
- 대상 날짜: 2026-06-02~2026-06-07, 2026-06-09~2026-06-13

Swift 테스트 fixture(`Packages/KboLiveCore/Tests/.../today-games-response.json`)는 앱 DTO 안정성 검증용으로 유지합니다.

### 4) 선수 기록 source HTML dump

```bash
npm run dump:players -- --kind all --write
npm run dump:players -- --kind batting --write
npm run dump:players -- --kind pitching --write
```

생성물:
- `fixtures/player-records-source/batting-latest.html`
- `fixtures/player-records-source/pitching-latest.html`
- timestamp별 `.html` / metadata `.json`

DB가 활성화된 일반 실행에서는 `raw_sources` table에도 `kbo-official-eng` source로 저장하고, leaders table을 parse해 `players`, `player_team_seasons`, batting/pitching season record table에 upsert합니다. 테스트 환경에서 DB 저장까지 확인하려면 `BASEBALL_LIVE_KR_DB_ENABLED=1`을 명시합니다.

## 검증 팁
- 경기 전 시간대에는 `changedGames: 0`이 정상일 수 있음
- 실제 live 검증은 경기 중 `events.ndjson`과 `changes/*.json`을 비교하면 됨
- `current`, `bases`, `count`, `inning` 변화가 잘 잡히는지 우선 확인
- `recentPlay`는 KBO source 문장 후보 필드가 있으면 우선 사용하고, 없으면 live 상황 요약 fallback을 생성함
- API 오류 응답은 `{ "error": { "code": "...", "message": "...", "statusCode": 400 } }` 형태로 표준화함

## 주의
- 현재는 spike scaffold 단계
- 실제 live polling 안정성/필드 매핑은 추가 검증 필요
- KBO endpoint는 브라우저 유사 헤더가 필요할 수 있음
