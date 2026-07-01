# Baseball LIVE KR Shared DTO Draft

작성일: 2026-06-10
상태: Working v0.2
기준 source: `backend-spike`의 `/games/today`, `/games/:gameId` normalized JSON

업데이트 메모 (2026-06-10):
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/DTO/GameDTO.swift`에 초안 DTO 구현 반영
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/GameDTOMapper.swift`에 blank-to-nil 및 backend basic ISO/extended ISO 겸용 startTime 파싱 반영
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Projections/`에 widget / live activity / menu bar용 projection 모델 추가
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/`에 projection mapper 초안 추가
- `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/Fixtures/today-games-response.json` fixture 및 projection 테스트 추가

## 1. 목표

Swift app / widget / live activity / macOS menu bar가 공통으로 소비할 **shared DTO 초안**을 정의한다.

핵심 원칙:
- backend-spike의 normalized 응답을 최대한 그대로 받는다
- Swift 클라이언트에서는 DTO와 domain model을 분리한다
- Widget / Live Activity는 shared DTO를 그대로 쓰지 않고 projection용 경량 DTO/domain으로 변환한다
- 아직 불안정한 필드는 optional로 둔다

---

## 2. 현재 backend 응답 기준

현재 `backend-spike` 기준 응답 shape:

### `GET /games/today?date=YYYY-MM-DD`
```json
{
  "date": "20260610",
  "games": [
    {
      "gameId": "20260610SKLG0",
      "date": "20260610",
      "venue": "잠실",
      "startTime": "20260610T18:30:00+09:00",
      "status": "scheduled",
      "awayTeam": { "id": "SK", "name": "SSG" },
      "homeTeam": { "id": "LG", "name": "LG" },
      "score": { "away": 0, "home": 0 },
      "inning": null,
      "count": null,
      "bases": { "first": false, "second": false, "third": false },
      "current": { "batter": "", "pitcher": "" },
      "probablePitchers": { "away": "", "home": "" },
      "recentPlay": null,
      "sourceMeta": {
        "rawStatusCode": "1",
        "rawTopBottomCode": null,
        "fetchedAt": "2026-06-10T02:18:13.565Z"
      }
    }
  ]
}
```

### `GET /games/:gameId?date=YYYY-MM-DD`
```json
{
  "date": "20260610",
  "game": {
    "gameId": "20260610SKLG0"
  }
}
```

---

## 3. DTO 계층 원칙

권장 계층:

```text
HTTP JSON
→ DTO (Codable)
→ Mapper
→ Domain Model
→ Feature-specific Projection
```

예시:

```text
TodayGamesResponseDTO
→ [GameDTO]
→ Game
→ WidgetGameSnapshot / ActivityGameState / MenuBarGameRowModel
```

원칙:
- `DTO`는 서버 응답 shape와 거의 1:1
- `Domain`은 앱 사용 관점에서 더 안전한 타입
- `Projection`은 target-specific 경량 모델

---

## 4. 권장 파일 배치

```text
Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/DTO/
├── TodayGamesResponseDTO.swift
├── GameDetailResponseDTO.swift
├── GameDTO.swift
├── TeamDTO.swift
├── ScoreDTO.swift
├── InningDTO.swift
├── CountDTO.swift
├── BasesDTO.swift
├── CurrentMatchupDTO.swift
├── ProbablePitchersDTO.swift
└── SourceMetaDTO.swift
```

초기에는 하나의 파일에 넣어도 되지만, 테스트와 diff를 생각하면 분리하는 편이 낫다.

---

## 5. Swift DTO 초안

### 5.1 TodayGamesResponseDTO

```swift
public struct TodayGamesResponseDTO: Decodable, Sendable {
    public let date: String
    public let games: [GameDTO]
}
```

### 5.2 GameDetailResponseDTO

```swift
public struct GameDetailResponseDTO: Decodable, Sendable {
    public let date: String
    public let game: GameDTO?
}
```

### 5.3 GameDTO

```swift
public struct GameDTO: Decodable, Identifiable, Sendable {
    public let gameId: String
    public let date: String
    public let venue: String?
    public let startTime: String?
    public let status: GameStatusDTO
    public let awayTeam: TeamDTO
    public let homeTeam: TeamDTO
    public let score: ScoreDTO
    public let inning: InningDTO?
    public let count: CountDTO?
    public let bases: BasesDTO?
    public let current: CurrentMatchupDTO?
    public let probablePitchers: ProbablePitchersDTO
    public let recentPlay: String?
    public let sourceMeta: SourceMetaDTO

    public var id: String { gameId }
}
```

### 5.4 하위 DTO

```swift
public struct TeamDTO: Decodable, Sendable {
    public let id: String
    public let name: String
}

public struct ScoreDTO: Decodable, Sendable {
    public let away: Int
    public let home: Int
}

public struct InningDTO: Decodable, Sendable {
    public let number: Int
    public let half: InningHalfDTO
}

public struct CountDTO: Decodable, Sendable {
    public let balls: Int
    public let strikes: Int
    public let outs: Int
}

public struct BasesDTO: Decodable, Sendable {
    public let first: Bool
    public let second: Bool
    public let third: Bool
}

public struct CurrentMatchupDTO: Decodable, Sendable {
    public let batter: String?
    public let pitcher: String?
}

public struct ProbablePitchersDTO: Decodable, Sendable {
    public let away: String?
    public let home: String?
}

public struct SourceMetaDTO: Decodable, Sendable {
    public let rawStatusCode: String?
    public let rawTopBottomCode: String?
    public let fetchedAt: String
}
```

### 5.5 enum DTO

```swift
public enum GameStatusDTO: String, Decodable, Sendable {
    case scheduled
    case live
    case final
    case delayed
    case cancelled
    case unknown
}

public enum InningHalfDTO: String, Decodable, Sendable {
    case top
    case bottom
}
```

---

## 6. 디코딩 안정성 규칙

현재 backend-spike는 점진적으로 shape가 보강될 예정이라, Swift 쪽에서는 아래를 권장한다.

### 권장 규칙
- 필드가 실제로 항상 오는 것이 확인되기 전까지 optional 허용을 보수적으로 검토
- 하지만 **server contract를 고정할 의도라면 DTO는 엄격하게 유지**
- 앱 레벨 fallback은 mapper/domain에서 처리

현재 추천:
- `gameId`, `date`, `status`, `awayTeam`, `homeTeam`, `score`, `sourceMeta`는 required
- `venue`, `startTime`, `inning`, `count`, `bases`, `current`, `recentPlay`는 optional 허용 유지
- `probablePitchers`는 object는 required, 내부 필드는 optional

---

## 7. Domain으로의 매핑 초안

DTO를 그대로 앱 전체에 퍼뜨리지 않는다.

권장 domain 타입:

```swift
public struct Game: Identifiable, Sendable, Equatable {
    public let id: String
    public let date: String
    public let venue: String?
    public let startTime: Date?
    public let status: GameStatus
    public let awayTeam: Team
    public let homeTeam: Team
    public let score: Score
    public let inning: InningState?
    public let count: CountState?
    public let bases: BasesState?
    public let current: CurrentMatchup?
    public let probablePitchers: ProbablePitchers
    public let recentPlay: String?
    public let sourceMeta: SourceMeta
}
```

매퍼 책임:
- `gameId` → `id`
- `startTime` 문자열 → `Date?`
- empty string → `nil` 정리
- `date`는 추후 `GameDate` 값 타입으로 승격 가능
- backend enum 문자열 → domain enum

---

## 8. empty string 정리 규칙

현재 backend fixture에서 아래 값이 보였다.
- `current.batter = ""`
- `current.pitcher = ""`

Swift mapper에서 권장 처리:

```swift
func nilIfBlank(_ value: String?) -> String? {
    guard let value, value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
        return nil
    }
    return value
}
```

적용 대상:
- `current.batter`
- `current.pitcher`
- `probablePitchers.away`
- `probablePitchers.home`
- 추후 `recentPlay`

즉 DTO는 raw contract를 받고,
**domain mapper에서 blank-to-nil normalize** 하는 것이 가장 안전하다.

---

## 9. Widget / Live Activity 전용 projection 초안

shared DTO를 직접 widget/live activity에 쓰지 않고 projection을 둔다.

### 9.1 WidgetGameSnapshot

```swift
public struct WidgetGameSnapshot: Sendable, Equatable {
    public let gameId: String
    public let awayTeamName: String
    public let homeTeamName: String
    public let awayScore: Int
    public let homeScore: Int
    public let status: GameStatus
    public let inningText: String?
    public let baseState: BasesState?
    public let recentPlay: String?
}
```

### 9.2 ActivityGameState

```swift
public struct ActivityGameState: Codable, Hashable, Sendable {
    public let awayScore: Int
    public let homeScore: Int
    public let status: ActivityStatus
    public let inningText: String?
    public let outs: Int?
    public let hasRunnerOnFirst: Bool
    public let hasRunnerOnSecond: Bool
    public let hasRunnerOnThird: Bool
    public let shortRecentPlay: String?
}
```

### 이유
- Live Activity는 state 크기를 작게 유지해야 함
- Widget은 timeline용 요약 모델이 더 적합함
- future backend change가 와도 projection mapper 하나로 방어 가능

---

## 10. Date/Time 처리 기준

현재 backend는 아래 두 날짜 표현을 혼합 사용 중이다.
- `date: "20260610"`
- `startTime: "2026-06-10T18:30:00+09:00"`

Swift 쪽 권장:
- DTO는 raw string 유지
- domain mapper에서 변환

권장 유틸:
- `KSTDateParser` 또는 `ISO8601KSTParser`
- `yyyymmdd` 파서 별도

향후 backend 권장 개선:
- `date`를 `YYYY-MM-DD`로 통일하거나
- `gameDate`와 `startTime` contract를 명확히 분리

현재는 앱에서 두 포맷을 모두 처리하는 방어 코드가 필요하다.

---

## 11. 에러/결측 처리 기준

DTO decode 실패는 네트워크/contract 문제로 간주한다.

권장 error 계층:

```swift
public enum APIError: Error, Sendable {
    case invalidResponse
    case decodingFailed
    case serverError(statusCode: Int)
    case emptyPayload
    case gameNotFound
}
```

UI fallback 원칙:
- Home: 결측 경기만 제외하지 말고 전체 refresh 에러로 표기
- Detail: `game == nil`이면 unavailable state 표시
- Widget: placeholder snapshot 사용
- Menu Bar: `데이터 불러오는 중` 또는 마지막 성공 상태 유지

---

## 12. 첫 구현 파일 우선순위

shared DTO 구현 시작 순서:
1. `GameDTO.swift`
2. `TodayGamesResponseDTO.swift`
3. `GameDetailResponseDTO.swift`
4. `GameStatusDTO.swift`
5. `GameDTOMapper.swift`
6. `Mock TodayGamesResponseDTO` fixture decode test

테스트 우선순위:
1. sample `/games/today` JSON decode 테스트
2. blank-to-nil mapper 테스트
3. `startTime` parse 테스트
4. `ActivityGameStateMapper` 축약 테스트

---

## 13. 현재 추천 결론

초기 shared contract는 **backend-spike normalized JSON을 그대로 받는 Codable DTO**로 시작하는 것이 가장 안전하다.

추천 방향은 다음과 같다.
- 서버 응답 shape = `DTO`
- 앱 내부 사용 타입 = `Domain`
- Widget/Live Activity = `Projection`

즉,
**DTO를 공통 계약으로 삼되, UI 타깃별로 바로 쓰지 말고 한 번 더 축약/정제하는 구조**가 가장 유지보수성이 좋다.
