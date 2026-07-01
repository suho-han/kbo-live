# Team And Player Records DB Plan

작성일: 2026-06-18
상태: Planning v0.1

## 1. 목적

Baseball LIVE KR의 현재 backend는 경기 목록과 팀 순위 일부를 normalized JSON으로 제공한다. 다음 단계에서는 팀 기록과 선수 기록을 DB에 누적해 앱이 경기 당일 상태뿐 아니라 시즌 흐름, 팀/선수 맥락, 상세 화면 보강 정보를 안정적으로 보여주도록 한다.

이 계획의 범위:

- 팀 시즌 기록 보강
- 선수 시즌 기록 보강
- 경기별 팀/선수 snapshot 저장
- DB schema 초안
- 수집/정규화/동기화 pipeline
- 앱 API 확장 순서

범위 밖:

- 상용 데이터 라이선스 확정
- 유료 데이터 공급사 연동
- pitch-by-pitch 전체 기록 완성
- 예측/AI 분석 모델

## 2. 현재 상태

구현됨:

- `backend-spike`가 KBO 공식 웹서비스를 호출한다.
- `/v1/games/today?date=YYYY-MM-DD`와 `/v1/games/:gameId?date=YYYY-MM-DD`가 동작한다.
- 월별 schedule과 날짜별 game list를 병합한다.
- `TeamRankDaily.aspx?date=YYYYMMDD`를 파싱해 `teamRecords`를 일부 보강한다.
- 승/패/세이브 투수명은 `pitcherDecisions`로 정규화된다.

약한 부분:

- 팀 기록이 경기 응답에 종속되어 있고 독립 조회 API가 없다.
- 선수 기록은 승패 투수명 수준이며 시즌/경기별 상세 기록이 없다.
- raw source snapshot은 fixture/log에 남지만 query 가능한 DB가 없다.
- source schema drift를 장기적으로 탐지할 저장 계층이 없다.
- 경기 상세 화면에서 사용할 `boxScore`, `lineupPreview`, `playerStats`, `analysis`가 비어 있다.

## 3. 원칙

1. 앱은 DB schema가 아니라 versioned API만 바라본다.
2. raw source와 normalized record를 모두 저장한다.
3. 날짜별 snapshot은 재현 가능해야 한다.
4. 팀/선수명 문자열만 저장하지 말고 stable id를 별도로 유지한다.
5. official KBO source를 1차로 쓰되, 부족한 선수 기록은 보조 source 후보를 별도 phase로 검증한다.
6. 기록 데이터는 live polling보다 낮은 빈도로 수집한다.
7. source parser 변경은 fixture 기반 regression test를 먼저 통과해야 한다.

## 4. 데이터 범위

### 4.1 Team Records

MVP 필드:

- team id
- team name
- season
- rank
- games
- wins
- losses
- draws
- win percentage
- games behind
- recent 10 games
- streak
- home record
- away record
- updated date

확장 필드:

- runs scored
- runs allowed
- run differential
- team batting average
- team ERA
- team OPS
- team WHIP
- last game result
- next game summary

### 4.2 Player Records

MVP 필드:

- player id
- player name
- team id
- season
- position group
- batting/pitching split
- games
- key counting stats
- key rate stats
- source updated date

타자 핵심 필드:

- PA
- AB
- H
- 2B
- 3B
- HR
- RBI
- R
- BB
- SO
- SB
- AVG
- OBP
- SLG
- OPS

투수 핵심 필드:

- G
- GS
- W
- L
- SV
- HLD
- IP
- H
- HR
- BB
- SO
- ER
- ERA
- WHIP

경기 상세 보강 필드:

- probable starter season summary
- current pitcher/batter season summary
- lineup player season summary
- game pitcher decision season summary

## 5. DB 선택

### Local / MVP

권장:

- SQLite
- migration file 기반 schema 관리
- backend packaged companion에 같이 포함 가능

이유:

- Mac mini/로컬 배포가 쉽다.
- 운영 DB 없이도 fixture와 cache를 query 가능하게 만들 수 있다.
- schema 실험 속도가 빠르다.

### Staging / Production

권장:

- PostgreSQL
- Prisma 또는 Drizzle 검토
- read-heavy endpoint를 위해 materialized snapshot table 또는 cache layer 병행

이유:

- long-running backend 운영 시 migration/backup/observability가 명확하다.
- 팀/선수 기록 query와 날짜별 snapshot query를 안정적으로 처리한다.
- 향후 API 트래픽 증가 시 read replica/cache 구성이 쉽다.

### 결정

초기 구현은 SQLite compatible schema로 시작한다. production 전환 시 PostgreSQL로 옮겨도 타입/인덱스 변경이 작도록 설계한다.

## 6. Schema 초안

### 6.1 Core Dimension Tables

```sql
create table teams (
  id text primary key,
  short_name text not null,
  full_name text not null,
  normalized_name text not null,
  active_from integer,
  active_to integer,
  created_at text not null,
  updated_at text not null
);

create table players (
  id text primary key,
  name text not null,
  normalized_name text not null,
  birth_date text,
  throws text,
  bats text,
  created_at text not null,
  updated_at text not null
);

create table player_team_seasons (
  player_id text not null,
  team_id text not null,
  season integer not null,
  uniform_number text,
  position text,
  primary key (player_id, team_id, season),
  foreign key (player_id) references players(id),
  foreign key (team_id) references teams(id)
);
```

### 6.2 Team Record Tables

```sql
create table team_season_records (
  season integer not null,
  date text not null,
  team_id text not null,
  rank integer,
  games integer,
  wins integer,
  losses integer,
  draws integer,
  winning_percentage real,
  games_behind text,
  recent_10 text,
  streak text,
  home_record text,
  away_record text,
  runs_scored integer,
  runs_allowed integer,
  source text not null,
  raw_source_id text,
  created_at text not null,
  updated_at text not null,
  primary key (season, date, team_id),
  foreign key (team_id) references teams(id)
);
```

### 6.3 Player Season Record Tables

```sql
create table player_batting_season_records (
  season integer not null,
  date text not null,
  player_id text not null,
  team_id text not null,
  games integer,
  plate_appearances integer,
  at_bats integer,
  hits integer,
  doubles integer,
  triples integer,
  home_runs integer,
  rbi integer,
  runs integer,
  walks integer,
  strikeouts integer,
  stolen_bases integer,
  avg real,
  obp real,
  slg real,
  ops real,
  source text not null,
  raw_source_id text,
  created_at text not null,
  updated_at text not null,
  primary key (season, date, player_id, team_id),
  foreign key (player_id) references players(id),
  foreign key (team_id) references teams(id)
);

create table player_pitching_season_records (
  season integer not null,
  date text not null,
  player_id text not null,
  team_id text not null,
  games integer,
  games_started integer,
  wins integer,
  losses integer,
  saves integer,
  holds integer,
  innings_pitched_outs integer,
  hits_allowed integer,
  home_runs_allowed integer,
  walks integer,
  strikeouts integer,
  earned_runs integer,
  era real,
  whip real,
  source text not null,
  raw_source_id text,
  created_at text not null,
  updated_at text not null,
  primary key (season, date, player_id, team_id),
  foreign key (player_id) references players(id),
  foreign key (team_id) references teams(id)
);
```

### 6.4 Game Snapshot Tables

```sql
create table games (
  game_id text primary key,
  season integer not null,
  date text not null,
  away_team_id text not null,
  home_team_id text not null,
  venue text,
  start_time text,
  status text not null,
  created_at text not null,
  updated_at text not null
);

create table game_snapshots (
  id text primary key,
  game_id text not null,
  captured_at text not null,
  status text not null,
  inning_number integer,
  inning_half text,
  away_score integer,
  home_score integer,
  raw_source_id text,
  normalized_json text not null,
  foreign key (game_id) references games(game_id)
);

create index idx_game_snapshots_game_time on game_snapshots(game_id, captured_at desc);
```

### 6.5 Raw Source Tables

```sql
create table raw_sources (
  id text primary key,
  source text not null,
  endpoint text not null,
  request_key text not null,
  fetched_at text not null,
  status_code integer,
  checksum text not null,
  body text not null
);

create unique index idx_raw_sources_checksum on raw_sources(source, endpoint, request_key, checksum);
```

## 7. 수집 Pipeline

### 7.1 Schedule / Game List

주기:

- 경기 있는 날: 30~60초
- 경기 없는 날: 10~30분
- 월별 schedule: 6시간

저장:

- `games`
- `game_snapshots`
- `raw_sources`

### 7.2 Team Records

주기:

- 매일 첫 요청 시 lazy refresh
- 경기 종료 후 5~10분 재수집
- 자정 이후 1회 보정 수집

저장:

- `team_season_records`
- `raw_sources`

초기 source:

- `TeamRankDaily.aspx?date=YYYYMMDD`

### 7.3 Player Records

주기:

- 경기 시작 전 1회
- 경기 종료 후 1회
- 자정 이후 1회 보정 수집

초기 source 후보:

- KBO 공식 기록 페이지 HTML
- KBO player ranking/stat 페이지
- 필요 시 Naver/Daum 보조 source

검증해야 할 것:

- 선수 stable id 확보 가능 여부
- 팀 이적/등록 말소 시 season affiliation 처리
- 타자/투수 page pagination 구조
- 날짜별 기록 snapshot 가능 여부

저장:

- `players`
- `player_team_seasons`
- `player_batting_season_records`
- `player_pitching_season_records`
- `raw_sources`

## 8. API 확장 계획

### Phase A: Team Records API

```text
GET /v1/teams/standings?season=2026&date=YYYY-MM-DD
GET /v1/teams/:teamId/record?season=2026&date=YYYY-MM-DD
```

앱 적용:

- Today 팀 순위 block
- 나의 팀 섹션
- 경기 상세의 팀 전력 비교

### Phase B: Player Search / Player Season API

```text
GET /v1/players/search?q=김&season=2026
GET /v1/players/:playerId/season?season=2026&date=YYYY-MM-DD
```

앱 적용:

- 상세 화면 선발 투수 season summary
- 현재 투수/타자 context
- 선수 상세 진입점

### Phase C: Game Detail Enrichment API

```text
GET /v1/games/:gameId/detail?date=YYYY-MM-DD
```

응답 포함 후보:

- game summary
- team records
- probable pitchers records
- pitcher decisions records
- lineup preview
- box score summary
- recent snapshot history

### Phase D: Admin / Debug API

```text
POST /internal/jobs/sync-team-records
POST /internal/jobs/sync-player-records
GET /internal/source-health
GET /internal/raw-sources?source=...
```

운영에서는 인증 또는 private network 뒤에 둔다.

## 9. 구현 단계

### Step 1. DB Foundation

작업:

- `backend-spike`에 SQLite 연결 추가
- migration runner 추가
- `raw_sources`, `teams`, `games`, `game_snapshots`부터 생성
- fixture 기반 seed script 작성

완료 기준:

- `npm test`에서 in-memory 또는 temp SQLite 사용
- 기존 `/v1/games/today` 응답 유지
- raw source 저장/중복 방지 테스트 통과

### Step 2. Team Records Persistence

작업:

- 기존 `teamRankMapper` 결과를 `team_season_records`에 upsert
- `/v1/teams/standings` 추가
- `/v1/games/today`는 DB team records를 우선 사용하고 source fallback 유지

완료 기준:

- 2026년 6월 fixture 날짜로 standings query 가능
- Today 화면의 나의 팀 전적/순위가 기존과 동일하게 표시됨

### Step 3. Player Source Spike

작업:

- KBO 공식 선수 기록 page endpoint/HTML 구조 조사
- 타자/투수 top-level stat dump script 작성
- player id 후보 추출
- raw fixture 저장
- mapper 초안 작성

완료 기준:

- 타자 1페이지, 투수 1페이지 fixture 저장
- player id/name/team/stat mapping test 작성
- source 이용 리스크 문서 업데이트

### Step 4. Player Records Persistence

작업:

- `players`, `player_team_seasons` upsert
- 타자/투수 season record upsert
- `/v1/players/search`, `/v1/players/:playerId/season` 추가

완료 기준:

- 특정 선수 season stats 조회 가능
- 동명이인 처리 정책 문서화
- 팀 이적 시 player/team/season row 분리 가능

### Step 5. Game Detail Integration

작업:

- `/v1/games/:gameId/detail` 응답 확장
- Swift DTO/domain 추가
- 상세 화면에 선발/승패투수/라인업 선수 season summary 표시

완료 기준:

- 상세 화면이 DB-backed records를 사용
- 기록 API 실패 시 기존 경기 상세 화면이 깨지지 않음

### Step 6. Production Hardening

작업:

- PostgreSQL migration compatibility 점검
- scheduled sync job 추가
- source failure metrics 추가
- parser drift alert 추가
- backup/export script 작성

완료 기준:

- staging에서 하루치 sync job 운영
- source 실패 시 stale DB snapshot으로 앱 응답 유지

## 10. 우선순위

1. DB foundation과 raw source 저장
2. 팀 기록 persistence와 standings API
3. 선수 기록 source spike
4. 선수 기록 persistence
5. 경기 상세 enrichment
6. production PostgreSQL 전환

## 11. 리스크

### 선수 stable id

KBO 공식 source에서 player id가 안정적으로 노출되지 않으면 이름+팀+생년월일 또는 상세 페이지 URL을 조합해야 한다. 이 경우 동명이인과 이적 처리가 어려워진다.

### source 라이선스

기록 데이터는 경기 상태보다 권리 이슈가 더 클 수 있다. 상용 배포 전에는 이용약관과 데이터 사용 범위를 확인해야 한다.

### HTML parser drift

팀 순위와 선수 기록 HTML 구조가 바뀌면 parser가 깨질 수 있다. raw fixture와 parser regression test가 필수다.

### DB와 live cache의 이중 truth

live 게임 상태는 cache가 빠르고, 기록은 DB가 안정적이다. API에서 최신성 기준을 명확히 분리해야 한다.

## 12. 바로 다음 작업

가장 먼저 할 일:

1. SQLite migration runner 추가
2. `raw_sources`, `teams`, `games`, `game_snapshots` migration 작성
3. 현재 `gameService` source 응답을 raw source table에 저장
4. fixture 기반 DB repository 테스트 작성
5. 그 다음 `team_season_records` persistence를 붙인다

## 13. 구현 로그

### 2026-06-18 Step 1 진행

완료:

- `backend-spike`에 `node:sqlite` 기반 DB 연결 추가
- migration runner 추가
- `schema_migrations`, `raw_sources`, `teams`, `games`, `game_snapshots` 생성
- KBO source client가 source 응답 body/status를 `raw_sources`에 저장
- `KBO_DB_PATH`, `KBO_DB_DISABLED` 지원
- raw source checksum dedupe repository 추가
- repository 및 KBO client persistence 테스트 추가

검증:

- `npm run typecheck` 통과
- `npm test` 통과
- `npm run build` 통과

다음:

- 선수 기록 source 후보 조사와 raw dump script 추가

### 2026-06-18 Step 2 진행

완료:

- `team_season_records` migration 추가
- `teams` upsert와 `team_season_records` upsert repository 추가
- 기존 `teamRankMapper` 결과를 standings load 시 DB에 저장
- `/v1/teams/standings` route alias 추가
- team record repository 테스트 추가
- source 실패 시 DB에 저장된 team records를 fallback으로 반환

검증:

- `npm run typecheck` 통과
- `npm test` 통과
- `npm run build` 통과

다음:

- 선수 기록 source spike 시작

### 2026-06-18 Step 3 시작

완료:

- 공식 영문 KBO batting leaders source 확인
  - `https://eng.koreabaseball.com/stats/battingLeaders.aspx`
- 공식 영문 KBO pitching leaders source 확인
  - `https://eng.koreabaseball.com/stats/pitchingLeaders.aspx`
- `npm run dump:players` script 추가
- `--kind all|batting|pitching`, `--write`, `--out-dir` 옵션 추가
- dry run에서 batting/pitching HTML fetch 성공
- DB 활성화 시 `raw_sources`에 `kbo-official-eng` source로 저장 가능

검증:

- `npm run typecheck` 통과
- `npm test` 통과
- `npm run build` 통과
- `KBO_DB_DISABLED=1 npm run dump:players -- --kind all` 통과

다음:

- Page2 source까지 확장해 OBP/SLG/OPS, BB/SO, WHIP 등 추가 stat 보강
- player records를 상세 화면 DTO에 연결

### 2026-06-23 Step 4 진행

완료:

- Korean hitter Basic2 parser 추가
  - BB/SO/OBP/SLG/OPS
- Korean pitcher Detail2 parser 추가
  - K/9, BB/9, K/BB, opponent OBP/SLG/OPS
- `collect:source --include-player-records`가 Basic2/Detail2를 함께 fetch/merge
- player season DB upsert가 walks/strikeouts/OBP/SLG/OPS/WHIP/ER 필드를 저장
- player record artifact에 `*-korean-detail-latest.html/json` 추가
- mapper/repository regression test 추가

검증:

- 실제 `collect:source --include-player-records` 실행 완료
- batting detailStats 30 / parsedRecords 20
- pitching detailStats 19 / parsedRecords 19
- sample DB 확인
  - `66606` 최원준: BB 39, SO 47, OBP .459, SLG .529, OPS .988
  - `55633` 올러: WHIP .95, BB 27, SO 92, ER 25

### 2026-06-23 Step 4 follow-up

완료:

- KBO-35 리뷰에서 지적된 Detail2 rate stats DB/API 미저장 gap 수정
- `player_pitching_season_records`에 Detail2 rate stat migration 추가
  - `strikeouts_per_nine`, `walks_per_nine`, `strikeout_walk_ratio`
  - `opponent_obp`, `opponent_slg`, `opponent_ops`
- repository upsert와 `/v1/players/:playerId/season` 반환 경로에 저장/조회 테스트 추가

### 2026-06-18 Step 3 구현

완료:

- batting leaders HTML parser 추가
- pitching leaders HTML parser 추가
- player link의 `pcode`를 stable player id 후보로 추출
- 영문 team name을 내부 team id로 매핑
- `players`, `player_team_seasons`, `player_batting_season_records`, `player_pitching_season_records` migration 추가
- batting/pitching season record upsert repository 추가
- player search repository 추가
- player season record repository 추가
- `/v1/players/search?q=NAME&season=YYYY` API 추가
- `/v1/players/:playerId/season?season=YYYY&date=YYYYMMDD` API 추가
- `npm run dump:players`가 HTML fetch 후 parse/upsert까지 수행

검증:

- `npm run typecheck` 통과
- `npm test` 통과
- `npm run build` 통과
- `KBO_DB_DISABLED=1 npm run dump:players -- --kind all` 통과
- dry run parsing result: batting 20명, pitching 20명

제약:

- 현재 parser는 batting/pitching leaders Page1 기준이다.
- Page1 source에는 batting OBP/SLG/OPS, BB/SO와 pitching WHIP/BB/SO/ER 등 일부 상세 stat가 없다.
- 다음 phase에서 Page2 또는 다른 공식 stat page를 추가로 붙여야 한다.
