#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend-spike"
OUTPUT_DIR="${ROOT_DIR}/.build/baseball-live-kr-backend-macos"
TEMP_OUTPUT_DIR="${ROOT_DIR}/.build/baseball-live-kr-backend-macos.tmp"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required to run the packaged backend." >&2
  exit 1
fi

cd "${BACKEND_DIR}"
npm run build

rm -rf "${TEMP_OUTPUT_DIR}"
mkdir -p "${TEMP_OUTPUT_DIR}"

cp -R "${BACKEND_DIR}/dist" "${TEMP_OUTPUT_DIR}/dist"
cp "${BACKEND_DIR}/package.json" "${TEMP_OUTPUT_DIR}/package.json"
cp "${BACKEND_DIR}/package-lock.json" "${TEMP_OUTPUT_DIR}/package-lock.json"
cp -R "${BACKEND_DIR}/node_modules" "${TEMP_OUTPUT_DIR}/node_modules"

SOURCE_DB="${BACKEND_DIR}/.data/baseball-live-kr.sqlite"
if [[ -f "${SOURCE_DB}" ]]; then
  mkdir -p "${TEMP_OUTPUT_DIR}/.data"
  cp "${SOURCE_DB}" "${TEMP_OUTPUT_DIR}/.data/baseball-live-kr.sqlite"
fi

cat > "${TEMP_OUTPUT_DIR}/run-backend.command" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js 22+ is required to run Baseball LIVE KR backend." >&2
  exit 1
fi

export NODE_ENV="${NODE_ENV:-production}"
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-17361}"

PACKAGED_DB="${DIR}/.data/baseball-live-kr.sqlite"
if [[ -f "${PACKAGED_DB}" ]]; then
  export BASEBALL_LIVE_KR_DB_ENABLED="${BASEBALL_LIVE_KR_DB_ENABLED:-1}"
  export BASEBALL_LIVE_KR_DB_PATH="${BASEBALL_LIVE_KR_DB_PATH:-${PACKAGED_DB}}"
fi

exec node "${DIR}/dist/src/index.js"
SCRIPT

chmod +x "${TEMP_OUTPUT_DIR}/run-backend.command"

cat > "${TEMP_OUTPUT_DIR}/README.txt" <<'TEXT'
Baseball LIVE KR Backend macOS bundle

Run:
  ./run-backend.command

Options:
  PORT=17361 ./run-backend.command
  HOST=127.0.0.1 PORT=17361 ./run-backend.command
  BASEBALL_LIVE_KR_DB_ENABLED=1 ./run-backend.command
  BASEBALL_LIVE_KR_DB_PATH=.data/baseball-live-kr.sqlite ./run-backend.command

Health check:
  curl http://127.0.0.1:17361/health

Requirement:
  Node.js 22+
TEXT

rm -rf "${OUTPUT_DIR}"
mv "${TEMP_OUTPUT_DIR}" "${OUTPUT_DIR}"

echo "Packaged backend: ${OUTPUT_DIR}"
