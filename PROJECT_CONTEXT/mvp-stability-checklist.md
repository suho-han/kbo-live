# MVP 안정화와 로컬 개발 검증 체크리스트

작성일: 2026-06-16

## 1. 목적

새 개발 세션에서 backend, Swift packages, Xcode app target을 같은 기준으로 검증한다.

## 2. 기본 검증 명령

전체 검증:

```bash
./scripts/verify-local.sh
```

빠른 검증:

```bash
SKIP_XCODE=1 ./scripts/verify-local.sh
```

개별 검증:

```bash
cd backend-spike && npm run typecheck && npm test && npm run build
cd Packages/BaseballLiveKRCore && swift test
cd Packages/BaseballLiveKRDesignSystem && swift build
cd Packages/BaseballLiveKRFeatures && swift test
xcodebuild -project BaseballLiveKR.xcodeproj -scheme BaseballLiveKRmacOS -destination 'platform=macOS' build
xcodebuild -project BaseballLiveKR.xcodeproj -scheme BaseballLiveKRiOS -destination 'generic/platform=iOS Simulator' build
```

## 3. 로컬 실행 체크리스트

1. `backend-spike` 의존성이 설치되어 있는지 확인한다.
2. backend를 실행한다.
3. `/v1/health`, `/v1/ready`가 200을 반환하는지 확인한다.
4. 앱 설정에서 backend preset 또는 Backend URL을 확인한다.
5. 오늘 경기 화면에서 loading, empty, error, loaded 상태를 확인한다.
6. 진행 중 경기 fixture가 필요하면 `KBO_USE_TEST_LIVE_GAME=1`로 backend를 실행한다.
7. macOS 메뉴바 popover에서 empty/live 상태와 설정 진입을 확인한다.

## 4. Demo Flow

1. `PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh`
2. macOS app에서 설정을 열고 Local preset을 확인한다.
3. 오늘 경기 목록이 로드되는지 확인한다.
4. 응원팀을 선택해 나의 팀 섹션이 갱신되는지 확인한다.
5. 경기 카드를 눌러 상세 화면으로 이동한다.
6. 메뉴바 아이콘을 열어 같은 상태가 compact하게 보이는지 확인한다.

## 5. Edge Case 점검

- backend가 꺼져 있을 때 사용자 메시지가 노출된다.
- 잘못된 backend URL 저장 시 상태 확인에서 실패 메시지가 노출된다.
- 경기가 없는 날짜는 "오늘은 경기가 없습니다." empty state가 표시된다.
- 응원팀을 선택하지 않은 Today 화면은 "응원팀을 선택해 주세요." CTA를 표시한다.
- 응원팀을 선택했지만 당일 경기가 없으면 "오늘은 응원팀 경기가 없습니다." fallback을 표시하고 리그 전체 목록으로 이어진다.
- 예정 경기는 점수 없이 시작 시간/구장 중심으로 표시된다.
- 진행 중 경기는 점수, 이닝, count/base 상태가 표시된다.
- 종료/취소/지연 경기는 필터에서 올바르게 분류된다.
- 두 자리 점수에서도 카드 layout이 깨지지 않는다.

## 6. P0 상태별 UX 회귀 체크

Today:

- loading: 첫 로드에서 "오늘 경기 데이터를 불러오는 중입니다."가 표시된다.
- empty: 경기가 없는 날짜는 리그 전체 섹션에 empty state가 표시된다.
- error: backend 연결 실패 시 Backend URL 확인 안내와 다시 시도 버튼이 표시된다.
- loaded: 응원팀 경기가 있으면 나의 팀 섹션에 우선 표시되고, 없으면 리그 전체로 이어진다.

Detail:

- scheduled: 점수보다 시작 시간, 구장, 선발 매치업을 우선한다.
- live: 점수, 이닝, 주자, count/current matchup을 표시하고 recentPlay가 있으면 별도 카드로 표시한다.
- final: 최종 전광판과 linescore/승패 투수 정보가 있으면 표시하고, 없으면 score와 teamRecords 중심으로 fallback한다.
- delayed/cancelled/unknown: live action을 숨기고 상태, 예정 시간, 구장을 우선 표시한다.

Menu Bar:

- loading: 헤더에 progress indicator가 표시된다.
- empty: 오늘 경기가 없으면 compact empty state가 표시된다.
- error: backend가 응답하지 않거나 URL이 없으면 "Backend URL 확인" CTA로 설정 진입을 제공한다.
- loaded: 응원팀 경기가 있으면 "나의 팀 경기"를 우선 표시하고, 없으면 대표 경기 하나를 fallback으로 표시한다.

## 7. Polling 기준

- 기본 polling interval은 `BaseballLiveKREnvironment.defaultPollingInterval`을 사용한다.
- backend cache TTL은 환경변수로 조정한다.
- live 경기 상태 변화는 backend polling fixture로 보관한다.

## 8. 완료 기준

- backend typecheck/test/build가 통과한다.
- Core/DesignSystem/Features 검증이 통과한다.
- iOS/macOS Xcode target build가 통과한다.
- README만 보고 backend와 앱을 실행할 수 있다.
- MVP demo flow가 backend on/off 양쪽에서 끊기지 않는다.
