#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.xcode/DerivedData}"
APP_PATH="${APP_PATH:-$DERIVED_DATA_PATH/Build/Products/Debug/BaseballLiveKR.app}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.build/transfer}"
STAGING_DIR="$ROOT_DIR/.build/macmini-runtime"
ARCHIVE_PATH="$OUT_DIR/kbo-live-macmini-runtime.tar.gz"

if [[ ! -d "$APP_PATH" ]]; then
  printf 'Missing macOS app bundle: %s\n' "$APP_PATH" >&2
  printf 'Build it first with: xcodebuild -project BaseballLiveKR.xcodeproj -scheme BaseballLiveKRmacOS -destination "platform=macOS" -derivedDataPath .xcode/DerivedData build\n' >&2
  exit 1
fi

"$ROOT_DIR/scripts/package-backend-macos.sh"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/.xcode/DerivedData/Build/Products/Debug" "$STAGING_DIR/.build" "$OUT_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/.xcode/DerivedData/Build/Products/Debug/$(basename "$APP_PATH")"
cp -R "$ROOT_DIR/.build/kbo-live-backend-macos" "$STAGING_DIR/.build/kbo-live-backend-macos"
mkdir -p "$STAGING_DIR/scripts"
cp "$ROOT_DIR/scripts/run-macos-app-with-packaged-backend.sh" "$STAGING_DIR/scripts/"
chmod +x "$STAGING_DIR/scripts/run-macos-app-with-packaged-backend.sh"
chmod +x "$STAGING_DIR/.build/kbo-live-backend-macos/run-backend.command"

tar -czf "$ARCHIVE_PATH" -C "$STAGING_DIR" .
printf 'Packaged Mac mini runtime: %s\n' "$ARCHIVE_PATH"
