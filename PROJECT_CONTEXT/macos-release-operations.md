# macOS Release And Remote Test Operations

작성일: 2026-06-17

## 1. 목적

Xcode 없이 `KboLivemacOS` 앱과 packaged backend companion을 앱 형태로 반복 테스트하기 위한 절차를 고정한다.

## 2. Local Build

macOS app build:

```bash
xcodebuild -project KboLiveApp.xcodeproj \
  -scheme KboLivemacOS \
  -destination 'platform=macOS' \
  -derivedDataPath .xcode/DerivedData \
  build
```

backend 검증:

```bash
cd backend-spike
npm run typecheck
npm test
npm run build
```

## 3. Runtime Packaging

Mac mini 전송용 runtime archive 생성:

```bash
./scripts/package-macmini-runtime.sh
```

생성물:

```text
.build/transfer/kbo-live-macmini-runtime.tar.gz
```

archive 포함 항목:

- `.xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app`
- `.build/kbo-live-backend-macos`
- `scripts/run-macos-app-with-packaged-backend.sh`

## 4. Local App + Backend 실행

```bash
PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

강제 재시작:

```bash
FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

live fixture 실행:

```bash
KBO_USE_TEST_LIVE_GAME=1 FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

## 5. Remote Mac Mini Smoke

runtime archive를 Mac mini에 업로드하고 backend health smoke를 실행:

```bash
SSH_TARGET=suhohan@100.114.89.25 \
REMOTE_DIR=/Users/suhohan/Projects/kbo-live \
PORT=3019 \
./scripts/deploy-macmini-runtime.sh
```

원격 실행:

```bash
cd /Users/suhohan/Projects/kbo-live
PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

## 6. Signing And Notarization

현재 상태:

- Debug/local 검증은 Xcode `Sign to Run Locally` 기준이다.
- notarization은 아직 release 필수 경로가 아니다.
- 외부 배포용 `.dmg` 또는 signed archive는 별도 후속 작업으로 둔다.

Release readiness procedure when Developer ID credentials are available:

```bash
APP_PRODUCT_NAME=BaseballLiveKR
APP_BUNDLE=".xcode/DerivedData/Build/Products/Release/${APP_PRODUCT_NAME}.app"
APP_ZIP=".build/transfer/${APP_PRODUCT_NAME}.zip"

xcodebuild -project KboLiveApp.xcodeproj \
  -scheme KboLivemacOS \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath .xcode/DerivedData \
  CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS='--options runtime' \
  build

ditto -c -k --keepParent \
  "${APP_BUNDLE}" \
  "${APP_ZIP}"

xcrun notarytool submit "${APP_ZIP}" \
  --keychain-profile baseball-live-kr-notary \
  --wait

xcrun stapler staple "${APP_BUNDLE}"
xcrun stapler validate "${APP_BUNDLE}"
spctl --assess --type execute --verbose=4 "${APP_BUNDLE}"
```

Credentials required:

- Developer ID Application certificate in the build keychain
- `notarytool` keychain profile named `baseball-live-kr-notary`
- Hardened runtime enabled for release signing

후속 결정:

- Developer ID Application 인증서 사용 여부
- hardened runtime 설정
- notarization 자동화 위치
- Sparkle 또는 자체 업데이트 채널 도입 여부

## 7. Versioning And Changelog

현재 XcodeGen 기준:

- `MARKETING_VERSION`: `0.1.0`
- `CURRENT_PROJECT_VERSION`: `1`

권장 정책:

- 사용자 테스트 archive 생성 시 `CURRENT_PROJECT_VERSION`을 증가시킨다.
- 기능 변경은 `feat`, 버그 수정은 `fix`, 운영 스크립트 변경은 `chore` prefix로 changelog 후보를 남긴다.
- remote smoke를 통과한 archive만 공유 대상으로 삼는다.

## 8. Pre-release Checklist

- backend `npm run typecheck` 통과
- backend `npm test` 통과
- backend `npm run build` 통과
- `KboLivemacOS` xcodebuild 통과
- `./scripts/package-macmini-runtime.sh` 통과
- `./scripts/verify-release-assets.sh .xcode/DerivedData/Build/Products .build/macmini-runtime .build/transfer` 통과
- archive 안에 `BaseballLiveKR.app`, packaged backend, run script 포함
- local `PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh` 실행 가능
- remote `deploy-macmini-runtime.sh` health smoke 통과
- 실제 경기 데이터 또는 live fixture로 메뉴바/메인 화면 확인
- release 후보는 `TeamBrandAssets`, `TeamWordmarks`, `TeamLogos`, logo, wordmark, emblem, mascot, team-ID PNG 파일명을 포함하지 않음
