# KBO Live Next Development Plan

작성일: 2026-06-12
상태: Working v0.1
기준 상태: backend spike 동작 확인, `BaseballLiveKRCore` networking/repository/polling 계층 구현 및 테스트 통과

## 1. 현재 기준선

구현 완료:
- `backend-spike` Fastify 서버
- `/health`
- `/games/today`
- `/games/:gameId`
- `/debug/source/today`
- KBO 원천 응답 fetch 및 normalized JSON 변환
- polling/dump script scaffold
- `BaseballLiveKRCore` DTO/domain/mapper/projection scaffold
- `BaseballLiveKRCore` API client, repository, polling service
- `BaseballLiveKRDesignSystem` token/theme/primitive scaffold
- 프로젝트 응답 규칙용 `AGENTS.md`

검증 완료:
- `backend-spike`: `npm run typecheck`, `npm test`, `npm run build`
- `BaseballLiveKRCore`: `swift test --disable-sandbox --manifest-cache local --cache-path .build/cache --config-path .build/config --security-path .build/security`

주요 공백:
- 실제 Xcode workspace/app targets 없음
- iOS/macOS/Widget/Live Activity 타깃 없음
- Swift 앱 state/view model/facade 없음
- `BaseballLiveKRDesignSystem` package build 검증 필요
- `recentPlay` 백엔드 매핑 미구현
- live 경기 중 polling fixture 추가 필요

## 2. 바로 다음 목표

다음 단계의 목표는 "실제 Apple app target에서 백엔드 데이터를 화면에 붙일 수 있는 최소 경로"를 만드는 것이다.

작업 순서:
1. `BaseballLiveKRDesignSystem` build 검증
2. `BaseballLiveKRCore` app-facing facade 추가
3. Xcode workspace/app target 생성
4. iOS Home 화면 mock/live 연결
5. Widget/Menu Bar/Live Activity projection 연결
6. 백엔드 live field 보강

## 3. Task A: DesignSystem 검증

목표:
- `BaseballLiveKRDesignSystem`이 현재 Swift toolchain에서 실제로 build 되는지 확인한다.

명령:
```bash
cd Packages/BaseballLiveKRDesignSystem
swift build --disable-sandbox --manifest-cache local --cache-path .build/cache --config-path .build/config --security-path .build/security
```

완료 기준:
- build 통과
- SwiftUI component compile error 없음
- token/component public API가 앱 타깃에서 import 가능한 형태인지 확인

예상 수정:
- Swift 6 concurrency 관련 static formatter/color helper 경고
- Preview 전용 코드 분리 필요 여부
- macOS/iOS availability annotation 정리

## 4. Task B: Core App Facade

목표:
- 앱 타깃이 repository를 직접 조립하지 않아도 되는 얇은 facade를 만든다.

추가 후보:
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/KboLiveEnvironment.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/GameFeedClient.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mocks/MockGameRepository.swift`

권장 API:
```swift
public struct GameFeedClient: Sendable {
    public func fetchTodayGames(date: String?) async throws -> TodayGames
    public func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetail
    public func streamTodayGames(date: String?) -> AsyncThrowingStream<TodayGames, Error>
}
```

완료 기준:
- app에서 `baseURL`만 넣으면 live client 구성 가능
- preview/test에서 mock repository 주입 가능
- `BaseballLiveKRCore` 테스트 추가 및 통과

## 5. Task C: Xcode Workspace And Targets

목표:
- 실제 앱 개발을 시작할 수 있는 workspace와 타깃을 만든다.

생성 후보:
- `KboLive.xcworkspace`
- `BaseballLiveKRApp/BaseballLiveKRApp.xcodeproj`
- `BaseballLiveKRApp/BaseballLiveKRiOS`
- `BaseballLiveKRApp/BaseballLiveKRmacOS`
- `BaseballLiveKRApp/BaseballLiveKRWidgetExtension`
- `BaseballLiveKRApp/KboLiveActivityExtension`

초기 방침:
- 앱 타깃은 Xcode에서 생성하고, 생성 산출물을 repo에 반영한다.
- package dependency는 `BaseballLiveKRCore`, `BaseballLiveKRDesignSystem`만 먼저 연결한다.
- signing/capability는 최소로 시작하고 Widget/Activity는 build 가능한 skeleton을 우선한다.

완료 기준:
- 빈 iOS app build 성공
- 빈 macOS MenuBarExtra app build 성공
- Widget/Activity extension target이 workspace에서 보임
- 두 Swift package import 가능

## 6. Task D: iOS Home MVP

목표:
- 오늘 경기 리스트를 한 화면에 보여준다.

구성:
- `TodayGamesView`
- `TodayGamesViewModel`
- `GameCardView`
- 상태 필터: 전체, 진행 중, 예정, 종료
- refresh action

데이터 흐름:
- Preview: mock repository
- Debug live: local backend `http://127.0.0.1:3000`
- Production placeholder: configurable `baseURL`

완료 기준:
- 백엔드가 켜져 있으면 실제 `/games/today` 응답 표시
- 백엔드가 꺼져 있으면 에러 상태 표시
- 예정/진행/종료 경기 카드가 모두 깨지지 않음

## 7. Task E: Widget/Menu Bar/Live Activity 연결

목표:
- 이미 있는 projection mapper를 실제 Apple surface에 연결한다.

순서:
1. Widget small timeline에 `WidgetGameSnapshot` 연결
2. macOS MenuBarExtra row에 `MenuBarGameSummary` 연결
3. Live Activity sample state에 `ActivityGameState` 연결

완료 기준:
- projection mapper를 중복 구현하지 않음
- 각 surface가 전체 `Game`이 아니라 표시 전용 모델을 사용
- 작은 화면에서 score/status/base/out 정보가 유지됨

## 8. Task F: Backend Live Field 보강

목표:
- 실제 live 경기 문맥 품질을 높인다.

우선순위:
- `recentPlay` 원천 후보 조사
- live 경기 중 polling fixture 추가 수집
- status mapping edge case 보강
- cancelled/delayed/doubleheader 응답 확인
- API error shape 정리

완료 기준:
- `recentPlay`가 가능한 경우 normalized JSON에 채워짐
- live polling 변화 로그에서 score/inning/count/bases/current 변화가 일관되게 잡힘
- Swift DTO fixture가 실제 응답과 계속 호환됨

## 9. 권장 다음 작업

가장 먼저 할 작업:
1. `BaseballLiveKRDesignSystem` build 검증
2. `GameFeedClient` facade 추가
3. Xcode workspace/app target 생성

이 순서가 좋은 이유:
- DesignSystem compile 여부를 먼저 확인해야 앱 target 생성 후 UI build 실패 원인을 줄일 수 있다.
- facade를 먼저 만들면 iOS, Widget, Menu Bar가 같은 데이터 조립 코드를 공유한다.
- Xcode target 생성 후에는 화면 구현에 바로 들어갈 수 있다.
