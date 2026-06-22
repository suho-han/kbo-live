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

생성물:

```text
backend-spike/artifacts/source-collection/<run-id>/manifest.json
backend-spike/artifacts/source-collection/<run-id>/dates/<YYYYMMDD>/source-normalized.json
backend-spike/artifacts/source-collection/<run-id>/player-records/batting-latest.html
backend-spike/artifacts/source-collection/<run-id>/player-records/pitching-latest.html
```

## 3. 수집 내용

날짜별 수집:

- `GetKboGameDate`
- `GetKboGameList`
- `GetScheduleList`
- normalized month games
- requested-date normalized games
- `TeamRankDaily` standings

선수 기록 수집:

- `eng.koreabaseball.com/stats/battingLeaders.aspx`
- `eng.koreabaseball.com/stats/pitchingLeaders.aspx`
- parser 결과 record count
- local DB upsert 결과 검증용 raw source 저장

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
