# 개발 및 검증

이 문서는 Baseball LIVE KR을 직접 개발하거나 배포 준비를 확인할 때 필요한 명령만 모아둡니다. 앱을 실행해 보고 싶은 경우에는 README의 `./scripts/kbo-live.sh run`을 먼저 사용하세요.

## 빠른 명령

```bash
./scripts/kbo-live.sh run
./scripts/kbo-live.sh live
./scripts/kbo-live.sh open
./scripts/kbo-live.sh verify
./scripts/kbo-live.sh package
```

## 전체 로컬 검증

```bash
./scripts/verify-local.sh
```

Xcode target build를 제외하고 빠르게 확인:

```bash
SKIP_XCODE=1 ./scripts/verify-local.sh
```

## Swift package

```bash
cd Packages/KboLiveCore
swift test
```

```bash
cd Packages/KboLiveFeatures
swift test
```

## Xcode project

프로젝트 파일은 `project.yml`에서 생성합니다.

```bash
/private/tmp/XcodeGen/.build/release/xcodegen generate
open BaseballLiveKR.xcodeproj
```

현재 포함 타깃:

- `BaseballLiveKRiOS`
- `BaseballLiveKRmacOS`
- `BaseballLiveKRWidgetExtension`

참고:

- 루트에 `KboLive.xcworkspace`도 같이 두었지만, 현재 샌드박스의 `xcodebuild -workspace` 검증은 통과하지 못했습니다.
- 실제 빌드 검증은 `BaseballLiveKR.xcodeproj` 기준으로 수행했습니다.

로컬 검증에 사용한 Xcode 명령:

```bash
xcodebuild -scheme BaseballLiveKRmacOS -project BaseballLiveKR.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build

xcodebuild -scheme BaseballLiveKRiOS -project BaseballLiveKR.xcodeproj -destination 'generic/platform=iOS Simulator' -derivedDataPath .xcode/DerivedData build
```

## 경기 데이터 설정

macOS 앱 기본 동작:

- `KBO_LIVE_BASE_URL`을 지정하지 않으면 앱 설정 또는 `http://127.0.0.1:17361`의 경기 데이터를 사용합니다.
- 앱은 기본적으로 최신 경기 정보용 주소를 호출합니다.
- iOS/macOS 앱의 설정 화면에서 `Local`, `Staging`, `Production` 데이터 주소를 선택하고 저장할 수 있습니다.
- `KBO_LIVE_BASE_URL` 환경변수가 있으면 앱 설정값보다 우선합니다.
- `KBO_LIVE_STAGING_BASE_URL`, `KBO_LIVE_PRODUCTION_BASE_URL`을 지정하면 설정 화면의 Staging/Production preset 초기 URL로 사용합니다.

## 데이터 서버만 실행

```bash
cd backend-spike
npm install
npm run dev
```

백그라운드 실행/종료:

```bash
./scripts/backend-start.sh
./scripts/backend-stop.sh
```

로그 확인:

```bash
tail -f backend-spike/logs/backend.log
```

Xcode 실행 전에 자동으로 백엔드를 켜고 싶으면 scheme의 `Run > Pre-actions`에 아래 스크립트를 넣습니다.

```bash
/Users/suhohan/Projects/kbo-live/scripts/backend-start.sh
```

## 테스트용 경기 데이터 수집

경기 중 상황을 나중에 다시 확인할 수 있도록 저장:

```bash
./scripts/run-kbo-live-fixture-capture.sh 20260616
```

저장 위치:

```text
backend-spike/logs/polling/<YYYYMMDD>/
backend-spike/fixtures/live-<YYYYMMDD>/
```

예정 경기 선발투수 시즌 기록만 수집해서 DB에 반영:

```bash
cd backend-spike
BASEBALL_LIVE_KR_DB_ENABLED=1 npm run collect:probable-pitchers -- --date 20260630 --write
```

## 배포 준비

macOS 배포와 원격 테스트 체크리스트는 `PROJECT_CONTEXT/macos-release-operations.md`를 기준으로 유지합니다.

Mac mini 테스트용 실행 파일 묶기:

```bash
./scripts/package-macmini-runtime.sh
```

Mac mini로 올리고 기본 실행 확인까지 진행:

```bash
SSH_TARGET=suhohan@100.114.89.25 REMOTE_DIR=/Users/suhohan/Projects/kbo-live ./scripts/deploy-macmini-runtime.sh
```

0.1.0 배포 준비 계획:

- 새 버전이 올라왔는지 앱에서 확인할 수 있게 하기
- 첫 배포 버전을 `0.1.0`으로 정리하기
- 버전별로 무엇이 좋아졌는지 기록하기
- macOS에서 내려받아 실행할 수 있는 파일 묶음 준비하기
- 정식 배포에 필요한 서명과 보안 확인은 다음 단계로 분리하기

## 참고 문서

- `PROJECT_CONTEXT/README.md`
- `PROJECT_CONTEXT/xcode-project-structure.md`
- `PROJECT_CONTEXT/forward-development-roadmap.md`
- `PROJECT_CONTEXT/backend-spike-results.md`
- `PROJECT_CONTEXT/production-backend-strategy.md`
- `PROJECT_CONTEXT/kbo-data-quality-regression-plan.md`
- `PROJECT_CONTEXT/kbo-data-validation-checklist.md`
- `PROJECT_CONTEXT/kbo-source-data-collection.md`
- `PROJECT_CONTEXT/app-productization-roadmap.md`
