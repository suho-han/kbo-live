# Baseball LIVE KR Backend Spike Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

작성일: 2026-06-10
상태: Working v0.2
개발 환경: 로컬 Mac 우선, 이후 임시 서버/로컬 실행 가능

업데이트 메모 (2026-06-10):

- `backend-spike/` Fastify scaffold 구현 및 로컬 실행 검증 완료
- `/health`, `/games/today`, `/games/:gameId`, `/debug/source/today` 동작 확인
- polling 스크립트에 `events.ndjson`, raw/normalized snapshots, latest fixture, change fixture 저장 기능 추가
- dump 스크립트에 raw + normalized payload fixture 저장 기능 추가
- 아직 실제 live 경기 시간대의 inning/count/bases/current 변화 검증은 추가로 필요

**Goal:** Baseball LIVE KR 앱용 중간 backend/BFF의 최소 기술 검증(spike)을 수행해 공식 KBO 데이터 소스를 안정적으로 수집·정규화할 수 있는지 확인한다.

**Architecture:** 공식 KBO 웹서비스를 backend가 polling하고, 응답을 앱 친화적인 JSON 모델로 정규화한 뒤 iOS/macOS/widget/live activity가 이 backend만 바라보도록 구성한다. spike 단계에서는 production-grade 배포보다 데이터 접근 안정성, 응답 구조 검증, 정규화 가능성, polling 리스크 파악에 집중한다.

**Tech Stack:** TypeScript, Node.js, Hono or Fastify, fetch/undici, zod, vitest, optional Redis/in-memory cache

---

## 1. spike 목적

이 spike는 완성형 backend를 만드는 작업이 아니다.

확인해야 할 핵심 질문:

1. 공식 KBO 웹서비스가 backend에서 안정적으로 호출되는가?
2. 어떤 헤더/요청 형식이 필수인가?
3. `GetKboGameList` 만으로 홈/위젯/메뉴바에 필요한 데이터가 충분한가?
4. 경기 중 polling 시 inning/count/bases/current player 필드가 실제로 유의미하게 변하는가?
5. 앱이 바로 소비할 수 있는 정규화 모델을 만들 수 있는가?
6. play-by-play / linescore 상세가 부족하다면 추가 source가 필요한가?

---

## 2. spike 비목표

이번 spike에서 하지 않을 것:

- production 배포 자동화
- APNs push 연동
- 인증/사용자 계정
- DB 영속화
- 전체 시즌 데이터 적재
- 장기 운영용 observability 완성
- 법무/약관 최종 확정

즉, 이번 단계는 **가능성 검증과 구조 결정**이 목적이다.

---

## 3. 현재까지 검증된 사실

기존 조사 문서 기준 확인된 사실:

- 공식 KBO 사이트는 일부 AJAX endpoint를 사용함
- 확인된 endpoint:
  - `https://www.koreabaseball.com/ws/Main.asmx/GetKboGameDate`
  - `https://www.koreabaseball.com/ws/Main.asmx/GetKboGameList`
  - `https://www.koreabaseball.com/ws/Schedule.asmx/GetScheduleList`
- 브라우저 유사 헤더 없이 호출하면 에러 HTML을 반환할 수 있음
- 브라우저 유사 헤더 포함 시 JSON/텍스트 응답을 받을 수 있었음
- `GetKboGameList` 에는 경기 ID, 팀명, 구장, 선발, 점수, 상태, 일부 live 경기 필드가 포함될 가능성이 확인됨

아직 미확정:

- full play-by-play structured endpoint
- inning linescore 상세 endpoint
- 경기 상세용 lineup / pitcher-batter / recent play structured source
- 장시간 polling 시 rate limit/차단 여부

---

## 4. spike 성공 기준

이번 spike가 성공으로 간주되려면 아래를 만족해야 한다.

### 필수 성공 기준

1. backend에서 KBO endpoint 3종 호출 성공
2. 필수 헤더 세트가 코드로 재현됨
3. 최소 `/health` 및 `/games/today` API 제공 가능
4. 앱 친화적 정규화 응답 스키마 초안 완성
5. 1회 이상 live polling 로그로 상태 변화 확인
6. 실패/빈 응답/에러 HTML 감지 로직 존재

### 추가 성공 기준

1. `recentPlay` 후보 필드 확보 또는 fallback 정책 정의
2. 응답 스키마를 zod 등으로 검증
3. 로컬 Mac에서 curl로 결과 재현 가능
4. 다음 단계에서 앱 연결 가능한 수준의 README/문서 확보

---

## 5. 권장 디렉터리 구조

backend spike는 앱 repo 안에 같이 두되, 독립 실행 가능하게 분리한다.

```text
kbo-live/
├── backend-spike/
│   ├── package.json
│   ├── tsconfig.json
│   ├── src/
│   │   ├── index.ts
│   │   ├── config/
│   │   ├── routes/
│   │   ├── clients/
│   │   ├── dto/
│   │   ├── mappers/
│   │   ├── services/
│   │   ├── validators/
│   │   └── utils/
│   ├── scripts/
│   │   ├── poll-live-games.ts
│   │   └── dump-kbo-response.ts
│   ├── fixtures/
│   ├── logs/
│   └── tests/
└── PROJECT_CONTEXT/
```

### 이유

- 앱/Swift 구조와 backend spike를 느슨하게 분리 가능
- 성공 시 추후 정식 `backend/` 로 승격하기 쉬움
- 스파이크 특성상 `scripts/`, `fixtures/`, `logs/` 가 중요함

---

## 6. 권장 스택 세부안

## 옵션 A: Hono

장점:

- 가벼움
- route 작성 빠름
- edge/Node 양쪽 확장성 있음

## 옵션 B: Fastify

장점:

- validation/plugin 생태계 좋음
- 서버형 구조가 명확함

### 현재 추천

- **Fastify** slightly 우세
- 이유: spike 이후 정식 backend로 이어질 때 구조가 더 직관적

### 공통 라이브러리 추천

- `zod`: 응답/내부 모델 검증
- `undici` 또는 Node native fetch: HTTP client
- `pino`: 로깅
- `vitest`: 테스트

---

## 7. 초기 내부 API 설계

spike는 아래 API만 있으면 충분하다.

## 7.1 GET `/health`

용도:

- 서버 실행 여부 확인
- 마지막 KBO fetch 결과 요약

응답 예시:

```json
{
  "ok": true,
  "source": "kbo-official",
  "lastFetchAt": "2026-06-10T10:45:00+09:00",
  "notes": []
}
```

## 7.2 GET `/games/today`

용도:

- 앱 홈/메뉴바/위젯 기본 공급

응답 예시:

```json
{
  "date": "2026-06-10",
  "games": [
    {
      "gameId": "20260610SKLG0",
      "status": "scheduled",
      "venue": "잠실",
      "startTime": "2026-06-10T18:30:00+09:00",
      "awayTeam": { "id": "SK", "name": "SSG" },
      "homeTeam": { "id": "LG", "name": "LG" },
      "score": { "away": 0, "home": 0 },
      "inning": null,
      "count": null,
      "bases": null,
      "current": null,
      "recentPlay": null
    }
  ]
}
```

## 7.3 GET `/games/:gameId`

용도:

- 경기 상세용 최소 단건 API
- spike에서는 today list를 필터링하는 수준이어도 됨

## 7.4 GET `/debug/source/today`

용도:

- 정규화 전 원본 응답 확인
- 앱용 endpoint와 debug endpoint 분리

주의:

- debug endpoint는 spike 전용
- 정식 backend에선 보호/삭제 가능

---

## 8. 정규화 모델 초안

backend 내부 표준 모델 예시:

```ts
export interface NormalizedGame {
  gameId: string
  date: string
  venue: string | null
  startTime: string | null
  status: 'scheduled' | 'live' | 'final' | 'delayed' | 'cancelled' | 'unknown'
  awayTeam: {
    id: string
    name: string
  }
  homeTeam: {
    id: string
    name: string
  }
  score: {
    away: number
    home: number
  }
  inning: {
    number: number
    half: 'top' | 'bottom'
  } | null
  count: {
    balls: number
    strikes: number
    outs: number
  } | null
  bases: {
    first: boolean
    second: boolean
    third: boolean
  } | null
  current: {
    batter: string | null
    pitcher: string | null
  } | null
  probablePitchers: {
    away: string | null
    home: string | null
  }
  recentPlay: string | null
  sourceMeta: {
    rawStatusCode: string | null
    rawTopBottomCode: string | null
    fetchedAt: string
  }
}
```

### 원칙

- 앱은 원천 KBO 필드명(`G_ID`, `T_SCORE_CN`)을 모르도록 한다
- source-specific 코드는 `sourceMeta` 아래로 격리
- `recentPlay` 가 불가능하면 null 허용

---

## 9. 상태 매핑 규칙 초안

예상 입력 필드:

- `GAME_STATE_SC`
- `GAME_INN_NO`
- `GAME_TB_SC`
- `BALL_CN`
- `STRIKE_CN`
- `OUT_CN`
- `B1_BAT_ORDER_NO`
- `B2_BAT_ORDER_NO`
- `B3_BAT_ORDER_NO`
- `T_P_NM`
- `B_P_NM`

spike에서 해야 할 일:

1. 실제 경기 시간에 raw field를 샘플링
2. 값 패턴을 수집
3. 내부 enum으로 매핑
4. 매핑 실패 시 `unknown` 과 raw 값 보존

### 중요

초기에는 상태 코드를 추측하지 말고 **로그 기반으로 매핑 표를 만든다.**

---

## 10. 필수 헤더 정책

현재까지 확인 기준으로 backend client는 최소 아래 헤더를 기본 탑재해야 한다.

```ts
{
  'User-Agent': 'Mozilla/5.0',
  'X-Requested-With': 'XMLHttpRequest',
  'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
  'Accept': 'application/json, text/javascript, */*; q=0.01',
  'Origin': 'https://www.koreabaseball.com',
  'Referer': 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx'
}
```

### spike에서 꼭 검증할 것

- endpoint별 referer 차이가 필요한지
- 헤더 일부 제거 시 실패하는지
- 응답이 JSON이 아니라 에러 HTML일 때 감지 가능한지

---

## 11. 로깅/실패 처리 요구사항

spike라도 반드시 아래는 있어야 한다.

### 필수 로그

- 요청 endpoint
- 요청 시간
- 응답 status
- content-type
- 응답 첫 200자 요약
- HTML 에러 페이지 감지 여부
- 정규화 성공/실패 건수

### 실패 처리

- JSON parse 실패 시 raw snippet 저장
- 필수 필드 누락 시 validation error 기록
- 연속 실패 시 `/health` 에 경고 노출

---

## 12. polling 검증 전략

## 스크립트 1: `poll-live-games.ts`

목적:

- live 경기 시간대에 15초 또는 30초 간격으로 `GetKboGameList` polling
- raw field 변화 기록

출력 예시:

- timestamp
- 경기 ID
- score 변화
- inning 변화
- count 변화
- base occupancy 변화
- batter/pitcher 변화

## 스크립트 2: `dump-kbo-response.ts`

목적:

- 특정 날짜 raw 응답 저장
- fixture 생성

### fixture 저장 이유

- 테스트 재현 가능
- live 경기 없는 시간에도 mapper 개발 가능
- 앱 쪽 mock 생성에도 활용 가능

---

## 13. 테스트 전략

spike에서도 최소 테스트는 필요하다.

## 단위 테스트

- 상태 매핑 함수
- base occupancy 매핑
- score/int parsing
- null/빈 문자열 처리

## fixture 기반 테스트

- scheduled game fixture
- live game fixture
- final game fixture
- malformed HTML error fixture

## 수동 검증

- `curl http://localhost:3000/health`
- `curl http://localhost:3000/games/today`
- live 경기 시간에 polling 로그 확인

---

## 14. 구현 태스크

### Task 1: backend spike scaffold 생성

**Objective:** 독립 실행 가능한 TypeScript backend skeleton을 만든다.

**Files:**

- Create: `backend-spike/package.json`
- Create: `backend-spike/tsconfig.json`
- Create: `backend-spike/src/index.ts`
- Create: `backend-spike/README.md`

**Steps:**

1. Node/TypeScript 프로젝트 초기화
2. dev/build/start script 추가
3. 기본 `/health` 라우트 추가
4. 로컬 실행 검증

---

### Task 2: KBO HTTP client 구현

**Objective:** 필수 헤더를 포함한 공식 KBO client를 만든다.

**Files:**

- Create: `backend-spike/src/clients/kboClient.ts`
- Create: `backend-spike/src/config/kboHeaders.ts`
- Test: `backend-spike/tests/kboClient.test.ts`

**Steps:**

1. 공통 header builder 작성
2. `GetKboGameDate` 호출 함수 작성
3. `GetKboGameList` 호출 함수 작성
4. `GetScheduleList` 호출 함수 작성
5. JSON/HTML 응답 판별 로직 추가

---

### Task 3: raw DTO / validator 작성

**Objective:** 원본 응답을 검증 가능한 구조로 분리한다.

**Files:**

- Create: `backend-spike/src/dto/kboGameDate.dto.ts`
- Create: `backend-spike/src/dto/kboGameList.dto.ts`
- Create: `backend-spike/src/dto/kboScheduleList.dto.ts`
- Create: `backend-spike/src/validators/`

**Steps:**

1. raw DTO 타입 작성
2. zod schema 작성
3. validation 실패 시 로그 규칙 추가

---

### Task 4: normalized mapper 구현

**Objective:** KBO raw 응답을 앱용 모델로 정규화한다.

**Files:**

- Create: `backend-spike/src/mappers/gameMapper.ts`
- Create: `backend-spike/src/mappers/statusMapper.ts`
- Create: `backend-spike/src/mappers/baseMapper.ts`
- Test: `backend-spike/tests/mappers/*.test.ts`

**Steps:**

1. score parsing 구현
2. 상태 코드 매핑 구현
3. inning/top-bottom 매핑 구현
4. base occupancy 매핑 구현
5. normalized model 생성

---

### Task 5: 앱용 라우트 구현

**Objective:** `/games/today` 와 `/games/:gameId` 를 제공한다.

**Files:**

- Create: `backend-spike/src/routes/health.ts`
- Create: `backend-spike/src/routes/games.ts`
- Create: `backend-spike/src/services/gameService.ts`

**Steps:**

1. today endpoint 구현
2. game detail endpoint 구현
3. debug raw endpoint 구현
4. 간단한 in-memory cache 추가

---

### Task 6: polling 스크립트 구현

**Objective:** 실시간 경기에서 필드 변화를 추적한다.

**Files:**

- Create: `backend-spike/scripts/poll-live-games.ts`
- Create: `backend-spike/scripts/dump-kbo-response.ts`
- Create: `backend-spike/logs/.gitkeep`
- Create: `backend-spike/fixtures/.gitkeep`

**Steps:**

1. 특정 date polling 스크립트 작성
2. interval 옵션 추가
3. raw/normalized diff 로그 기록
4. fixture 저장 기능 추가

---

### Task 7: spike 결과 문서화

**Objective:** 확인된 것과 미확정 사항을 PROJECT_CONTEXT에 기록한다.

**Files:**

- Modify: `PROJECT_CONTEXT/kbo-data-source-research.md`
- Create: `PROJECT_CONTEXT/backend-spike-results.md`

**Steps:**

1. 성공한 endpoint/헤더 조합 기록
2. live polling 결과 기록
3. 정규화 가능한 필드/불가능한 필드 분리
4. 다음 단계 backend 전환 권고안 작성

---

## 15. 로컬 Mac 실행 커맨드 예시

```bash
cd backend-spike
npm install
npm run dev
```

health 확인:

```bash
curl http://localhost:3000/health
```

today games 확인:

```bash
curl http://localhost:3000/games/today | jq
```

polling 스크립트 예시:

```bash
npm run poll -- --date 2026-06-10 --interval 15 --iterations 20 --save-raw
```

단건 dump + fixture 저장:

```bash
npm run dump -- --date 2026-06-10 --write
```

---

## 16. 산출물 체크리스트

spike 완료 시 남아 있어야 하는 것:

- 실행 가능한 local backend
- KBO client 코드
- raw fixture 파일
- normalized response 예시
- polling 로그 예시
- known issues 목록
- 다음 단계 권고 문서

---

## 17. 리스크 및 의사결정 포인트

### 리스크 1. unofficial endpoint 안정성

대응:

- source client를 모듈로 격리
- 원천 변경 시 mapper/client만 수정 가능하게 유지

### 리스크 2. live 상세 정보 부족

대응:

- `recentPlay` 를 optional로 두고 null 허용
- 필요 시 보조 source 조사 spike 추가

### 리스크 3. rate limiting / 차단

대응:

- polling interval 보수적으로 시작
- 캐시 적용
- fetch 실패율 기록

### 리스크 4. 앱이 필요로 하는 정보와 source 간 gap

대응:

- 앱 MVP 요구사항을 `games/today` 기준으로 먼저 제한
- 상세 play-by-play는 별도 phase로 분리

---

## 18. 현재 추천 결론

이 backend spike는 **앱 개발 전에 반드시 해볼 가치가 있는 고레버리지 작업**이다.

가장 추천하는 실행 순서:

1. backend scaffold 생성
2. KBO client + 필수 헤더 재현
3. `/games/today` 정규화 응답 생성
4. live polling 스크립트로 필드 변화 검증
5. 결과에 따라 앱 MVP 데이터 모델 확정

한 줄로 정리하면:

> 먼저 backend spike로 원천 데이터의 현실을 확인하고, 그 결과를 기준으로 Swift 앱 모델과 Live Activity 범위를 확정하는 것이 가장 안전하다.
