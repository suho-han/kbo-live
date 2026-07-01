# Baseball LIVE KR Forward Development Roadmap

작성일: 2026-06-12
업데이트: 2026-06-14
상태: Working v0.1
목표: 현재 backend spike와 shared Swift package 상태에서 실제 Apple 플랫폼 MVP까지 가는 개발 계획을 정의한다.

## 1. 제품 목표

MVP의 목표는 KBO 오늘 경기를 Apple 플랫폼에서 빠르게 확인하는 것이다.

핵심 사용자 경험:
- iPhone에서 오늘 경기 목록과 경기 상태 확인
- 진행 중 경기의 점수, 이닝, 아웃, 주자 상태 확인
- Widget에서 관심 경기 점수 확인
- Live Activity에서 진행 중 경기 추적
- macOS Menu Bar에서 짧은 스코어 요약 확인

MVP에서 제외:
- 계정/로그인
- 서버 push 기반 실시간 업데이트
- 상세 기록/타자별 기록/라인업 전체
- 앱스토어 배포 자동화
- Android/Web 클라이언트

## 2. 현재 상태

구현된 것:
- `backend-spike` Fastify 서버
- KBO 공식 웹서비스 호출
- normalized game JSON 응답
- 월 단위 schedule + 날짜별 game list 병합
- `/health`
- `/games/today`
- `/games/:gameId`
- `/debug/source/today`
- `BaseballLiveKRCore` domain/DTO/mapper/projection
- `BaseballLiveKRCore` networking/repository/polling service
- `BaseballLiveKRDesignSystem` token/theme/primitive scaffold
- Xcode workspace/project
- iOS app target
- macOS menu bar target
- Widget extension
- SwiftUI Today Games / Game Detail 화면
- macOS 메뉴바 서버 상태 확인 UI
- Discord connector 응답 규칙용 `AGENTS.md`

검증된 것:
- `backend-spike` typecheck/test/build 통과
- `BaseballLiveKRCore` Swift test 16개 통과
- 실제 KBO 응답 기준 `/games/today` 정상 동작 확인
- 2026-06-14 기준 6월 전체 schedule 90경기 로드 확인
- `BaseballLiveKRmacOS` Xcode build 통과

아직 없는 것:
- Live Activity extension
- local backend base URL 설정 UI
- `recentPlay` 백엔드 매핑

## 3. 개발 원칙

우선순위:
1. macOS 앱 제품화 완료: 메뉴바/메인 창/packaged backend/원격 Mac-mini smoke/스크린샷 검증
2. 실제로 빌드되는 Apple target 유지
3. 작고 안정적인 shared Core API
4. iOS Home, Widget, Live Activity 실제 기기 검증
5. live 경기 품질 개선

구현 원칙:
- source of truth는 초기에는 backend spike/BFF로 둔다.
- Swift 앱은 KBO 원천 endpoint를 직접 호출하지 않는다.
- `Game` domain 모델은 공유하되 Widget/Live Activity/Menu Bar는 projection 모델만 사용한다.
- polling은 MVP 기본값으로 사용한다.
- push/APNs는 구조만 열어두고 MVP 이후로 미룬다.
- 디자인 시스템은 앱 target보다 먼저 build 검증한다.

## 4. Milestone 0: 정리 및 검증

목표:
- 현재 추가된 Core networking 계층과 DesignSystem을 모두 검증 가능한 상태로 만든다.

작업:
- `BaseballLiveKRDesignSystem` Swift build 실행
- DesignSystem compile error 수정
- `BaseballLiveKRCore` 테스트 명령 README 또는 validation checklist에 반영
- `.connect/` 파일을 git에 포함할지 제외할지 결정
- 현재 변경분을 기능 단위로 커밋할 준비

완료 기준:
- `Packages/BaseballLiveKRCore` test 통과
- `Packages/BaseballLiveKRDesignSystem` build 통과
- `AGENTS.md` 규칙 확인
- 현재 작업 트리 변경이 의도별로 구분됨

권장 커밋:
- `docs: add project agent response rules`
- `feat(core): add live game networking repository and polling`
- `docs(plan): add forward development roadmap`

## 5. Milestone 1: Core App Facade

목표:
- Apple app target이 Core networking을 쉽게 사용할 수 있게 한다.

작업:
- `GameFeedClient` 추가
- live client factory 추가
- mock repository 추가
- base URL 설정 타입 추가
- polling interval 기본값 정의
- facade 테스트 추가

예상 파일:
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/GameFeedClient.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/BaseballLiveKREnvironment.swift`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mocks/MockGameRepository.swift`
- `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/GameFeedClientTests.swift`

완료 기준:
- 앱에서 `GameFeedClient.live(baseURL:)` 형태로 조립 가능
- preview/test에서 mock client 사용 가능
- Core test 통과

## 6. Milestone 2: Xcode Workspace 및 Target 생성

목표:
- 실제 Apple 플랫폼 앱 개발을 시작할 수 있는 workspace를 만든다.

작업:
- `BaseballLiveKR.xcworkspace` 생성
- `BaseballLiveKR.xcodeproj` 생성
- iOS app target 생성
- macOS app target 생성
- Widget extension 생성
- Live Activity extension 생성
- `BaseballLiveKRCore`, `BaseballLiveKRDesignSystem` package 연결

완료 기준:
- iOS app 빈 화면 build 성공
- macOS app 빈 MenuBarExtra build 성공
- Widget extension build 성공
- Live Activity extension build 성공
- 모든 target에서 shared package import 가능

주의:
- signing은 local development 기준으로 최소 설정한다.
- capability 설정은 Widget/Activity build가 되는 수준까지만 먼저 한다.
- 자동 생성된 Xcode 파일 변경은 가능한 한 target 생성 커밋에만 묶는다.

## 7. Milestone 3: iOS Home MVP

목표:
- 오늘 경기 목록을 iPhone 앱에서 볼 수 있게 한다.

작업:
- app container 구성
- `TodayGamesViewModel` 추가
- `TodayGamesView` 추가
- `GameCardView` 추가
- loading/error/empty 상태 추가
- pull-to-refresh 추가
- mock/live 데이터 전환 방식 추가

화면 요구사항:
- 오늘 날짜 표시
- 전체 경기 목록
- 진행 중 경기 우선 정렬
- 예정/진행/종료 상태 표시
- 팀명/점수/구장/시작시간 표시
- live 경기의 이닝/아웃/주자 표시

완료 기준:
- backend가 켜져 있으면 실제 `/games/today` 응답 표시
- backend가 꺼져 있으면 사용자가 이해 가능한 에러 상태 표시
- mock preview가 항상 동작
- iPhone small/regular width에서 레이아웃 깨짐 없음

## 8. Milestone 4: Game Detail MVP

목표:
- 특정 경기의 상세 상태를 확인할 수 있게 한다.

작업:
- `GameDetailViewModel` 추가
- `GameDetailView` 추가
- score header 추가
- inning/count/bases section 추가
- current batter/pitcher 표시
- probable pitchers 표시
- polling refresh 연결

완료 기준:
- Home에서 경기 선택 시 detail 진입
- `/games/:gameId` 응답 표시
- live 경기에서 polling update 반영
- scheduled/final 상태에서도 화면이 빈약하지 않음

## 9. Milestone 5: Widget MVP

목표:
- 홈 화면 Widget에서 관심 경기 또는 대표 경기 스코어를 확인한다.

작업:
- small widget layout
- medium widget layout
- timeline provider scaffold
- `WidgetGameSnapshotMapper` 연결
- mock timeline 추가
- refresh policy 정의

완료 기준:
- Widget preview 표시
- small widget에서 팀/점수/상태가 읽힘
- medium widget에서 주자/최근 플레이 영역까지 표시 가능
- Widget extension이 전체 `Game`이 아니라 `WidgetGameSnapshot`을 사용

## 10. Milestone 6: macOS Menu Bar MVP

목표:
- macOS 메뉴바에서 경기 요약을 짧게 확인한다.

작업:
- MenuBarExtra app entry 추가
- menu bar title formatter 연결
- dropdown game list 추가
- favorite placeholder 추가
- manual refresh 추가

완료 기준:
- 메뉴바에 대표 경기 요약 표시
- dropdown에서 오늘 경기 목록 표시
- `MenuBarGameSummary` 사용
- 백엔드 오류 시 메뉴바가 비정상 종료되지 않음

## 11. Milestone 7: Live Activity MVP

목표:
- 진행 중 경기를 Lock Screen/Dynamic Island에 표시한다.

작업:
- Activity attributes 정의
- Activity content state 정의
- `ActivityGameState` 연결
- iOS app에서 start/stop action 추가
- Lock Screen layout 추가
- Dynamic Island compact/minimal/expanded layout 추가

완료 기준:
- iOS app에서 live activity 시작 가능
- mock state로 layout preview 가능
- `ActivityGameState`만 Activity UI에 전달
- 너무 큰 payload를 Activity state에 넣지 않음

## 12. Milestone 8: Backend Live 품질 개선

목표:
- live 경기 상태의 신뢰도를 높인다.

작업:
- live 경기 시간대 polling fixture 수집
- `recentPlay` 원천 후보 조사
- `recentPlay` mapping 구현
- delayed/cancelled/doubleheader fixture 확보
- status mapper test 보강
- normalized API error shape 정의

완료 기준:
- `recentPlay`가 가능한 경기에서 채워짐
- live score/count/base/current 변화가 fixture로 검증됨
- Swift DTO fixture가 백엔드 응답과 일치
- 앱에서 오류 메시지를 일관되게 처리 가능

## 13. Milestone 9: MVP 안정화

목표:
- 로컬에서 반복 개발 가능한 MVP 품질을 만든다.

작업:
- 앱 target build matrix 정리
- Core/DesignSystem test/build 명령 문서화
- backend-spike 실행 체크리스트 정리
- UI edge case 점검
- 네트워크 timeout/retry 정책 결정
- polling interval 조정
- logging 추가

완료 기준:
- 새 개발자가 README만 보고 backend와 app을 띄울 수 있음
- Core/DesignSystem/backend 검증 명령이 모두 통과
- MVP demo flow가 끊기지 않음

## 14. 권장 작업 순서

1. `BaseballLiveKRDesignSystem` build 검증
2. `GameFeedClient` facade 구현
3. 현재 변경분 커밋 정리
4. Xcode workspace 및 target 생성
5. iOS Home MVP 구현
6. Game Detail MVP 구현
7. Widget MVP 구현
8. macOS Menu Bar MVP 구현
9. Live Activity MVP 구현
10. backend live field 보강
11. MVP 안정화

## 15. 리스크와 대응

KBO 원천 API 변경:
- DTO schema validation과 fixture를 계속 유지한다.
- `/debug/source/today`를 유지해서 raw 응답을 바로 확인한다.

live data 품질 부족:
- polling fixture를 경기 중 수집한다.
- UI는 값이 없을 때도 자연스럽게 fallback한다.

Widget/Live Activity 제한:
- 표시 전용 projection 모델을 유지한다.
- 네트워크와 상태 저장은 extension 내부에서 최소화한다.

Xcode project churn:
- target 생성 커밋과 기능 구현 커밋을 분리한다.
- 자동 생성 파일 변경을 unrelated refactor와 섞지 않는다.

Discord connector 알림:
- `AGENTS.md`의 completion mention 규칙을 유지한다.
- 최종 응답 시작에 role mention이 빠졌는지 확인한다.
