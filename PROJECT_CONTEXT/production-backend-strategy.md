# KBO Live Production Backend Strategy

작성일: 2026-06-16
상태: Working v0.2

## 1. 목적

`backend-spike`를 운영 가능한 backend로 전환하기 위한 기준을 정리한다.

이 문서는 아래 결정을 고정한다.

- `backend-spike`와 production backend의 경계
- local, staging, production 배포 방식
- KBO source 호출/cache/rate limit 정책
- API versioning과 backward compatibility
- health/readiness/observability
- runtime config와 secret 관리
- 장애, timeout, cache fallback 정책

## 2. 결론

권장 경로:

1. MVP와 원격 수동 테스트는 현재 `backend-spike` packaged companion을 유지한다.
2. staging은 long-running API로 먼저 만든다.
3. production도 초기에는 long-running API를 우선한다.
4. cloud function은 traffic이 낮고 cold start가 허용되는 보조 후보로만 둔다.
5. 앱은 `local`, `staging`, `production` backend URL을 명시적으로 전환할 수 있어야 한다.

이유:

- KBO source는 월별 schedule과 날짜별 game list를 병합해야 해서 request fan-out이 있다.
- live polling, cache warming, fixture 수집, schema drift 감지를 long-running process가 가장 단순하게 처리한다.
- cloud function은 cold start와 burst 호출 제어가 까다롭고, 장기 polling/fixture 운영에 불리하다.
- Mac local companion은 개발과 데모에는 좋지만 다중 사용자 production backend로는 부적합하다.

## 3. backend-spike와 production backend 경계

`backend-spike`에 남길 것:

- KBO source 조사
- raw dump
- fixture capture
- mapper 실험
- live 상태 회귀 테스트
- local packaged backend smoke

production backend로 승격할 것:

- normalized API route
- source client
- cache layer
- rate limit guard
- health/readiness endpoint
- structured logging
- error response contract
- API versioning
- config validation

분리 기준:

- `backend-spike`는 깨져도 앱 production 동작에 영향을 주지 않는 실험 영역이어야 한다.
- production backend는 앱이 의존하는 안정 계약만 포함해야 한다.
- spike에서 검증된 mapper와 DTO는 production package로 이동하거나 shared module로 추출한다.

## 4. 배포 옵션 비교

### Option A: Mac local app companion

용도:

- 개발
- 원격 Mac mini 수동 테스트
- 오프라인 데모

장점:

- 현재 이미 동작한다.
- 앱과 백엔드 버전을 묶어서 테스트하기 쉽다.
- KBO source 문제와 앱 UI 문제를 빠르게 분리할 수 있다.

단점:

- 사용자별 로컬 Node runtime 의존성이 생긴다.
- 운영 observability가 약하다.
- 앱스토어 배포 모델과 맞지 않는다.

결론:

- MVP 개발/QA용으로 유지한다.
- production 사용자 대상 기본 경로로 쓰지 않는다.

### Option B: Cloud function

용도:

- 저빈도 read API
- 간단한 `/health`
- cache hit 위주 endpoint

장점:

- 운영 부담이 낮다.
- 사용량이 적을 때 비용이 낮다.
- 배포/rollback이 단순할 수 있다.

단점:

- KBO source fan-out 요청에서 timeout 위험이 크다.
- cold start가 live UX에 영향을 줄 수 있다.
- background polling과 fixture 수집이 부자연스럽다.

결론:

- production v1 기본안으로는 보류한다.
- cache layer가 충분히 안정화된 뒤 edge read endpoint 후보로 재검토한다.

### Option C: Long-running API

용도:

- staging/production 기본 backend
- KBO source polling/cache warming
- observability와 error tracking
- fixture 기반 회귀 운영

장점:

- live polling과 cache warming을 단순하게 구현할 수 있다.
- request fan-out과 timeout 제어가 쉽다.
- readiness, metrics, structured logging을 붙이기 좋다.

단점:

- 배포/운영 표면이 cloud function보다 넓다.
- 최소 인프라 비용이 발생한다.
- process supervision, rolling deploy, secret 관리가 필요하다.

결론:

- staging과 production 기본 배포 방식으로 선택한다.

## 5. 환경 전략

환경:

- `local`: packaged companion 또는 `backend-spike` dev server
- `staging`: production backend 후보를 배포한 검증 환경
- `production`: 앱 기본 연결 대상

앱 전환 규칙:

- 환경변수 `KBO_LIVE_BASE_URL`이 최우선이다.
- 앱 설정의 backend preset과 저장된 Backend URL이 그 다음이다.
- 앱 설정은 `local`, `staging`, `production` preset을 제공한다.
- `KBO_LIVE_STAGING_BASE_URL`, `KBO_LIVE_PRODUCTION_BASE_URL`은 staging/production preset의 초기 URL로 사용한다.
- 현재 앱 기본 local URL은 `http://127.0.0.1:17361`이고, production 빌드에서는 production URL을 기본 선택한다.
- 별도 `custom` preset은 두지 않는다. 각 preset의 URL 입력값을 저장할 수 있으므로 임시 endpoint 검증은 선택한 preset의 URL override로 처리한다.

권장 config:

```text
KBO_LIVE_ENV=local|staging|production
KBO_LIVE_BASE_URL=https://...
KBO_LIVE_STAGING_BASE_URL=https://staging.example...
KBO_LIVE_PRODUCTION_BASE_URL=https://api.example...
KBO_SOURCE_TIMEOUT_MS=3000
KBO_CACHE_TTL_SCHEDULE_SEC=21600
KBO_CACHE_TTL_GAME_IDLE_SEC=60
KBO_CACHE_TTL_GAME_LIVE_SEC=5
KBO_CACHE_STALE_IF_ERROR_SEC=600
```

## 6. KBO source 호출 정책

원칙:

- 앱 요청 1회가 KBO source fan-out으로 바로 이어지지 않게 한다.
- schedule은 긴 TTL, live game list는 짧은 TTL로 분리한다.
- source 장애 시 가능한 한 stale cache를 반환한다.

TTL 초안:

- 월별 schedule: 6시간
- 오늘 경기 list, 경기 전/종료: 60초
- 오늘 경기 list, live 포함: 5초
- stale-if-error: 10분

rate limit guard:

- 동일 date 요청은 in-flight request를 deduplicate한다.
- source timeout은 endpoint별로 3초 내로 제한한다.
- source 연속 실패 시 짧은 circuit breaker를 둔다.
- KBO source 호출량은 date 단위로 로그 집계한다.

## 7. API versioning

초기 versioning:

- `/v1/health`
- `/v1/ready`
- `/v1/games/today?date=YYYY-MM-DD`
- `/v1/games/:gameId?date=YYYY-MM-DD`

호환성 정책:

- 기존 필드는 의미를 바꾸지 않는다.
- enum 값 추가는 가능하지만 앱은 unknown fallback을 유지한다.
- 필드 삭제/rename은 v2에서만 한다.
- optional 필드는 null 가능성을 유지한다.
- error shape는 `{ "error": { "code", "message", "statusCode" } }`를 유지한다.

현재 `/games/today`는 MVP local 호환용으로 유지하고, 앱 API client 기본값은 `/v1/games/today`를 사용한다.

## 8. Health, readiness, observability

Endpoint:

- `/health`: process alive
- `/ready`: config validation, cache backend 연결, KBO source reachability 최근 상태
- `/metrics`: production에서는 인증 또는 private network 뒤에 둔다.

로그:

- request id
- date/gameId
- source call count
- source latency
- cache hit/miss/stale
- normalized game count
- error code

알림 기준:

- KBO source 연속 실패
- cache stale 반환 지속
- normalized game count 급변
- unknown status 비율 증가
- p95 latency 상승

## 9. 장애와 fallback 정책

정상 응답:

- fresh cache가 있으면 fresh 반환
- fresh cache가 없고 source 호출 성공 시 반환 후 cache 저장

source timeout/error:

- stale cache가 있으면 stale 반환하고 `sourceMeta` 또는 response metadata에 stale 여부를 남긴다.
- stale cache도 없으면 normalized error shape로 503을 반환한다.

앱 UX:

- 200 + stale data: 기존 목록 유지, 마지막 갱신 시각 표시
- 503: “경기 데이터를 불러오지 못했습니다” + 재시도
- invalid date 400: 사용자 입력 오류로 표시

## 10. Secret과 config

현재 KBO source는 별도 secret이 없지만, production backend에는 아래 config validation을 둔다.

- required env 누락 시 boot fail
- timeout/cache TTL numeric validation
- allowed origin/app version policy
- production debug endpoint 비활성화

민감 정보가 생기면:

- local: `.env.local`
- staging/production: hosting provider secret manager
- repo에는 secret 값 저장 금지

## 11. Production 전환 단계

Phase 1: harden backend-spike

- `/v1` route 추가
- cache abstraction 추가
- source call deduplication 추가
- readiness endpoint 추가
- contract test 유지

Phase 2: production backend package 분리

- `backend/` 또는 workspace package 생성
- spike-only dump/poll scripts와 runtime route 분리
- deployment config 추가
- staging URL 발급

Phase 3: app environment 전환

- app build config별 default backend URL 분리
- Settings UI에서 local/staging/production preset 제공
- production URL smoke checklist 추가

현재 구현 상태:

- `BackendSettingsModel`은 local/staging/production preset을 제공한다.
- `KBO_LIVE_BASE_URL`은 모든 preset보다 우선한다.
- `KBO_LIVE_STAGING_BASE_URL`, `KBO_LIVE_PRODUCTION_BASE_URL`은 각 preset의 초기 URL로 사용한다.
- 앱 설정에서 저장한 preset별 URL은 재시작 후에도 유지된다.

Phase 4: operationalize

- log/metrics dashboard
- fixture capture job
- source schema drift alert
- release checklist

## 12. Open Questions

- production hosting 후보를 어디로 둘 것인가: Fly.io, Render, Railway, Cloud Run, VPS 중 선택 필요
- cache backend는 process memory로 시작할지 Redis/SQLite를 바로 둘지 결정 필요
- production에서 `/debug/source/today`를 완전히 제거할지 private auth 뒤에 둘지 결정 필요
- 앱스토어 배포 시 local backend 설정 UI를 숨길지 developer mode로 남길지 결정 필요

## 13. 다음 작업

권장 Linear follow-up:

- `/v1` route compatibility 추가
- memory cache + in-flight dedupe 구현
- `/ready` endpoint 추가
- staging hosting 후보 2개 비교 spike
- app backend environment preset UI 추가
