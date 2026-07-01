#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_TARGET="${SSH_TARGET:-suhohan@100.114.89.25}"
REMOTE_DIR="${REMOTE_DIR:-/Users/suhohan/Projects/kbo-live}"
PORT="${PORT:-17361}"
SMOKE_PORT="${SMOKE_PORT:-3019}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/.build/transfer/baseball-live-kr-macmini-runtime.tar.gz}"

"$ROOT_DIR/scripts/package-macmini-runtime.sh"

printf 'Uploading %s to %s:%s\n' "$ARCHIVE_PATH" "$SSH_TARGET" "$REMOTE_DIR"
ssh "$SSH_TARGET" "mkdir -p '$REMOTE_DIR'"
scp "$ARCHIVE_PATH" "$SSH_TARGET:$REMOTE_DIR/baseball-live-kr-macmini-runtime.tar.gz"

ssh "$SSH_TARGET" "cd '$REMOTE_DIR' && tar -xzf baseball-live-kr-macmini-runtime.tar.gz && chmod +x scripts/run-macos-app-with-packaged-backend.sh .build/baseball-live-kr-backend-macos/run-backend.command"

printf 'Running remote backend health smoke on port %s\n' "$SMOKE_PORT"
ssh "$SSH_TARGET" "cd '$REMOTE_DIR' && PORT=$SMOKE_PORT .build/baseball-live-kr-backend-macos/run-backend.command >/tmp/baseball-live-kr-backend-$SMOKE_PORT.log 2>&1 & pid=\$!; for i in {1..20}; do if ! kill -0 \$pid 2>/dev/null; then cat /tmp/baseball-live-kr-backend-$SMOKE_PORT.log; exit 1; fi; if curl -fsS --max-time 1 http://127.0.0.1:$SMOKE_PORT/health; then kill \$pid; wait \$pid 2>/dev/null || true; exit 0; fi; sleep 0.25; done; cat /tmp/baseball-live-kr-backend-$SMOKE_PORT.log; kill \$pid 2>/dev/null || true; exit 1"

cat <<EOF

Remote runtime deployed.

Run on Mac mini:
cd $REMOTE_DIR
PORT=$PORT ./scripts/run-macos-app-with-packaged-backend.sh
EOF
