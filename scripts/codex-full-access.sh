#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

exec codex \
  --sandbox danger-full-access \
  --ask-for-approval never \
  --search
