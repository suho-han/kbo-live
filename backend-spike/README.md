# KBO Live Backend Spike

Fastify 기반 KBO Live backend spike 뼈대입니다.

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
- `GET /games/today?date=YYYY-MM-DD`
- `GET /games/:gameId?date=YYYY-MM-DD`
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

## 검증 팁
- 경기 전 시간대에는 `changedGames: 0`이 정상일 수 있음
- 실제 live 검증은 경기 중 `events.ndjson`과 `changes/*.json`을 비교하면 됨
- `current`, `bases`, `count`, `inning` 변화가 잘 잡히는지 우선 확인

## 주의
- 현재는 spike scaffold 단계
- 실제 live polling 안정성/필드 매핑은 추가 검증 필요
- KBO endpoint는 브라우저 유사 헤더가 필요할 수 있음
- `recentPlay`는 아직 미매핑
