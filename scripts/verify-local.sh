#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.xcode/DerivedData}"

run() {
  printf '\n==> %s\n' "$*"
  "$@"
}

cd "$ROOT_DIR/backend-spike"
run npm test
run npm run build

cd "$ROOT_DIR/Packages/BaseballLiveKRCore"
run swift test

cd "$ROOT_DIR/Packages/BaseballLiveKRDesignSystem"
run swift build

cd "$ROOT_DIR/Packages/BaseballLiveKRFeatures"
run swift test

if [[ "${SKIP_XCODE:-0}" == "1" ]]; then
  printf '\nSKIP_XCODE=1, skipping Xcode target builds.\n'
  exit 0
fi

cd "$ROOT_DIR"
run xcodebuild \
  -project BaseballLiveKR.xcodeproj \
  -scheme BaseballLiveKRmacOS \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

run xcodebuild \
  -project BaseballLiveKR.xcodeproj \
  -scheme BaseballLiveKRiOS \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build
