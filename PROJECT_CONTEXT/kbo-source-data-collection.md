# KBO 추가 소스 데이터 수집

작성일: 2026-06-22
상태: Working v0.1
관련 Linear: KBO-28

## 1. 목적

UI 실사용 검증 전에 원천 데이터를 폭넓게 확보한다. 날짜별 KBO game/schedule/standings와 영문 선수 리더보드 HTML을 한 번에 수집하고, 후속 mapper/fixture 승격에 쓸 manifest를 남긴다.

## 2. 빠른 실행

여러 날짜 game/schedule/standings 수집:

```bash
cd backend-spike
npm run collect:source -- --dates 20260614,20260621,20260622,20260623 --write
```

선수 기록 원천까지 함께 수집:

```bash
cd backend-spike
npm run collect:source -- --dates 20260614,20260621,20260622,20260623 --include-player-records --write
```

팀/선수/리그 세부 기록 원천까지 함께 수집:

```bash
cd backend-spike
npm run collect:source -- --dates 20260621 --include-player-records --include-extra-records --write
```

생성물:

```text
backend-spike/artifacts/source-collection/<run-id>/manifest.json
backend-spike/artifacts/source-collection/<run-id>/dates/<YYYYMMDD>/source-normalized.json
backend-spike/artifacts/source-collection/<run-id>/dates/<YYYYMMDD>/team-records.json
backend-spike/artifacts/source-collection/<run-id>/player-records/batting-latest.html
backend-spike/artifacts/source-collection/<run-id>/player-records/batting-records-latest.json
backend-spike/artifacts/source-collection/<run-id>/player-records/pitching-latest.html
backend-spike/artifacts/source-collection/<run-id>/player-records/pitching-records-latest.json
backend-spike/artifacts/source-collection/<run-id>/extra-records/team/*.html
backend-spike/artifacts/source-collection/<run-id>/extra-records/team/*.json
backend-spike/artifacts/source-collection/<run-id>/extra-records/player/*.html
backend-spike/artifacts/source-collection/<run-id>/extra-records/player/*.json
backend-spike/artifacts/source-collection/<run-id>/extra-records/league/*.html
backend-spike/artifacts/source-collection/<run-id>/extra-records/league/*.json
```

## 3. 수집 내용

날짜별 수집:

- `GetKboGameDate`
- `GetKboGameList`
- `GetScheduleList`
- normalized month games
- requested-date normalized games
- `TeamRankDaily` standings
- parsed team record JSON: rank, wins, losses, draws, win rate, games back, recent 10, streak

선수 기록 수집:

- `eng.koreabaseball.com/stats/battingLeaders.aspx`
- `eng.koreabaseball.com/stats/pitchingLeaders.aspx`
- 한국어 이름 보정용 `www.koreabaseball.com/Record/Player/HitterBasic/Basic1.aspx`
- 한국어 이름 보정용 `www.koreabaseball.com/Record/Player/PitcherBasic/Basic1.aspx`
- raw HTML
- parsed batting record JSON: rank, games, PA, AB, R, H, 2B, 3B, HR, TB, RBI, SB, CS, SAC, SF, AVG
- parsed pitching record JSON: rank, games, CG, SHO, W, L, SV, HLD, PCT, PA, NP, IP outs, hits/extra-base allowed, HR, ERA
- 영문 source의 `playerId`를 기준으로 한국어 기록 페이지 이름을 매칭해 `playerName`은 한글로 저장
- local DB upsert 결과 검증용 raw source 저장

추가 기록 소스 수집:

- 팀 타격: `Record/Team/Hitter/Basic1.aspx`, `Basic2.aspx`
- 팀 투수: `Record/Team/Pitcher/Basic1.aspx`, `Basic2.aspx`
- 팀 수비/주루: `Record/Team/Defense/Basic.aspx`, `Record/Team/Runner/Basic.aspx`
- 선수 타격: `Record/Player/HitterBasic/Basic2.aspx`, `Detail1.aspx`
- 선수 투수: `Record/Player/PitcherBasic/Basic2.aspx`, `Detail1.aspx`, `Detail2.aspx`
- 선수 수비/주루: `Record/Player/Defense/Basic.aspx`, `Record/Player/Runner/Basic.aspx`
- 리그 컨텍스트: `Record/Ranking/Top5.aspx`, `Record/Expectation/WeekList.aspx`, `Record/Crowd/GraphTeam.aspx`
- 각 페이지별 raw HTML과 table/row/column metadata JSON

옵션:

- `--include-extra-records`: 위 세부 기록 전체 수집
- `--extra-records team`: 팀 기록만 수집
- `--extra-records player`: 선수 세부 기록만 수집
- `--extra-records team-hitter-basic1,player-pitcher-detail1`: 특정 id만 수집

## 4. 날짜 선정 기준

우선 수집 후보:

- `20260614`: cancelled catalog가 있는 날짜
- `20260621`: 최근 완료 경기 5개가 있는 날짜
- `20260622`: 경기 없는 월요일/휴식일 검증
- `20260623`: 예정 경기/다음 경기 검증 후보

추가 후보:

- live 경기 진행 중 날짜
- 우천 지연/취소 발생 날짜
- 더블헤더 발생 날짜
- 포스트시즌/올스타처럼 schedule shape가 달라질 수 있는 날짜

## 5. 수집 후 판정

manifest에서 확인한다.

- `rawGames`: 요청 날짜의 KBO raw game count
- `requestedScheduleGames`: 요청 날짜 schedule count
- `requestedNormalizedGames`: 요청 날짜 normalized game count
- `normalizedGames`: 월 단위 merged normalized game count
- `standings`: standings count, 정상은 10
- `statuses`: final/scheduled/live/cancelled/delayed 분포
- `playerSources[].parsedRecords`: batting/pitching parser가 추출한 선수 수

## 6. 보존 정책

`artifacts/source-collection/`은 수집 산출물이며 git에는 넣지 않는다. 회귀 가치가 있는 날짜만 선별해 `backend-spike/fixtures/catalog/` 또는 `backend-spike/fixtures/202606-completed/`로 승격한다.
