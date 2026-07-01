# KBO 데이터 품질, fixture, 회귀 테스트 체계

작성일: 2026-06-20
상태: Working v0.1
관련 Linear: KBO-16

## 1. 목적

KBO 공식 웹 원천은 공개 개발자 API가 아니므로 필드명, 상태 코드, HTML fragment, 응답 shape가 예고 없이 바뀔 수 있다. backend는 원천 변경을 흡수하고, 앱은 stable normalized contract만 소비해야 한다.

이 문서는 fixture 수집, contract fixture, schema drift 감지, Swift DTO 동기화 기준을 하나로 고정한다.

## 2. 현재 구현 상태

이미 구현된 기준:

- `scripts/run-kbo-live-fixture-capture.sh`로 live polling fixture를 수집한다.
- `backend-spike/fixtures/catalog/`에 장기 보관 edge-case fixture를 raw + normalized 쌍으로 승격한다.
- backend contract test가 `makeTestLiveGame` 결과와 Swift DTO fixture `live-test-game-response.json`의 JSON shape 일치를 검증한다.
- Swift Core DTO test가 live fixture의 score/count/base/current/teamRecords/boxScore/recentPlay decode와 mapping을 검증한다.
- backend mapper test가 `recentPlay` 원천 필드와 live context fallback을 검증한다.
- backend service test가 source 실패 시 cache 또는 DB-backed standings fallback을 검증한다.

현재 catalog coverage:

- `cancelled`: `backend-spike/fixtures/catalog/cancelled/20260614-NCKT0-*`에 실제 KBO `우천취소` schedule row를 보관한다.
- `delayed`: 아직 실제 raw fixture가 없다.
- `doubleheader`: 아직 실제 raw fixture가 없다.

아직 운영 절차로 남겨야 하는 기준:

- delayed/doubleheader fixture catalog를 지속적으로 채운다.
- 원천 schema drift 감지 테스트를 fixture catalog 기준으로 확장한다.
- backend fixture와 Swift DTO fixture 변경은 같은 PR 또는 같은 작업 단위로 검증한다.

## 3. Fixture Catalog

대표 catalog는 `backend-spike/fixtures/` 아래에 보관한다.

필수 상태:

- `scheduled`: 경기 전, 선발/구장/시간 중심.
- `live`: score, inning, count, bases, current, recentPlay 포함.
- `final`: 최종 점수, 승패 투수, boxScore/linescore 가능 여부 확인.
- `delayed`: 우천/기타 지연 상태 코드와 표시 문구 확인.
- `cancelled`: 취소 상태 코드와 score null/zero 처리 확인.
- `doubleheader`: 같은 팀/날짜 복수 경기, gameId 충돌 여부 확인.

권장 경로:

```text
backend-spike/fixtures/live-<YYYYMMDD>/
backend-spike/fixtures/202606-completed/<YYYYMMDD>/
backend-spike/fixtures/catalog/<status>/<YYYYMMDD>-<gameId>.json
```

`catalog/`는 원천 raw와 normalized snapshot을 같이 남기는 장기 보관용이다. live polling 산출물 중 회귀 가치가 있는 snapshot만 catalog로 승격한다. 실제 fixture를 확보하지 못한 상태는 `catalog/README.md`에 재시도 조건을 기록한다.

## 4. 수집 절차

경기 중 live fixture 수집:

```bash
./scripts/run-kbo-live-fixture-capture.sh 20260620
```

권장 환경변수:

```bash
INTERVAL_SECONDS=30 ITERATIONS=480 ./scripts/run-kbo-live-fixture-capture.sh 20260620
```

수집 후 확인:

1. `events.ndjson`에서 score, inning, count, bases 변화가 기록됐는지 확인한다.
2. raw snapshot에 원천 상태 코드와 주요 필드가 남았는지 확인한다.
3. normalized snapshot이 `/v1/games/today` contract와 같은 shape인지 확인한다.
4. 회귀 가치가 있는 snapshot을 `fixtures/catalog/`로 복사한다.
5. 새로운 상태 코드가 있으면 `statusMapper` test를 추가한다.

## 5. Contract Test 기준

backend contract:

```bash
cd backend-spike
npm test -- --run tests/contract.test.ts
```

Swift DTO contract:

```bash
cd Packages/BaseballLiveKRCore
swift test
```

변경 원칙:

- normalized JSON field를 추가할 수는 있지만 기존 required field를 제거하지 않는다.
- enum raw value가 늘어나면 앱 mapper는 unknown fallback을 유지한다.
- nullable field가 required로 바뀌면 backend와 Swift DTO test를 같은 작업에서 수정한다.
- `recentPlay`는 없을 수 있으므로 UI fallback을 전제로 optional을 유지한다.

## 6. Schema Drift 감지

원천 drift는 다음 조건을 실패로 본다.

- `GetKboGameList` 응답에서 필수 game id/date/team/status 필드가 사라짐.
- live count/base/current 후보 필드가 모두 비어 있음.
- status code가 mapper의 known 또는 unknown fallback 경로를 통과하지 못함.
- schedule parser가 당일 gameId를 하나도 복원하지 못함.
- normalized response가 Swift DTO fixture와 shape 호환성을 잃음.

단기 감지는 fixture 기반 test로 처리하고, production backend 전환 후에는 polling job에서 drift warning을 남긴다.

## 7. 완료 기준

KBO-16은 다음 기준을 만족하면 완료로 본다.

- live 대표 fixture가 backend와 Swift DTO 양쪽에서 검증된다.
- `recentPlay`, score, inning, count, bases, current mapping test가 있다.
- backend normalized contract fixture와 Swift DTO fixture가 동기화되어 있다.
- source 실패 시 cache 또는 DB-backed fallback test가 있다.
- delayed/cancelled/doubleheader는 catalog 확보 후 mapper test를 추가하는 후속 작업으로 분리되어 있다.
