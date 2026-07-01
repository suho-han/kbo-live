#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/.build/kbo-live-backend-macos"
APP_PATH="${APP_PATH:-${ROOT_DIR}/.xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app}"
PORT="${PORT:-17361}"
FORCE_RESTART="${FORCE_RESTART:-0}"
PID_FILE="${BACKEND_DIR}/backend.pid"
LOG_FILE="${BACKEND_DIR}/backend.log"

backend_is_healthy() {
  curl -fsS --max-time 2 "http://127.0.0.1:${PORT}/v1/health" >/dev/null 2>&1
}

print_backend_start_failure() {
  echo "backend failed to become healthy on port ${PORT}" >&2
  if [[ -f "${PID_FILE}" ]]; then
    echo "pid: $(cat "${PID_FILE}")" >&2
  fi
  if [[ -s "${LOG_FILE}" ]]; then
    echo "last backend log lines:" >&2
    tail -n 80 "${LOG_FILE}" >&2
  else
    echo "backend log is empty: ${LOG_FILE}" >&2
  fi
}

wait_for_backend_health() {
  local pid="$1"
  local attempt

  for attempt in {1..30}; do
    if backend_is_healthy; then
      return 0
    fi
    if ! kill -0 "${pid}" 2>/dev/null; then
      print_backend_start_failure
      exit 1
    fi
    sleep 0.5
  done

  print_backend_start_failure
  exit 1
}

if [[ ! -x "${BACKEND_DIR}/run-backend.command" ]]; then
  "${ROOT_DIR}/scripts/package-backend-macos.sh"
fi

if [[ ! -d "${APP_PATH}" ]]; then
  echo "macOS app bundle not found: ${APP_PATH}" >&2
  echo "Build it first with: xcodebuild -project BaseballLiveKR.xcodeproj -scheme BaseballLiveKRmacOS -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build" >&2
  exit 1
fi

APP_EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${APP_PATH}/Contents/Info.plist" 2>/dev/null || true)"
if [[ -z "${APP_EXECUTABLE_NAME}" ]]; then
  APP_EXECUTABLE_NAME="$(basename "${APP_PATH}" .app)"
fi
APP_EXECUTABLE="${APP_PATH}/Contents/MacOS/${APP_EXECUTABLE_NAME}"

if [[ ! -x "${APP_EXECUTABLE}" ]]; then
  echo "macOS app executable not found: ${APP_EXECUTABLE}" >&2
  exit 1
fi

find_app_pids() {
  local pid
  local command
  local matched_pids=()

  while IFS= read -r pid; do
    command="$(ps -p "${pid}" -o command= 2>/dev/null || true)"
    if [[ "${command}" == "${APP_EXECUTABLE}"* ]]; then
      matched_pids+=("${pid}")
    fi
  done < <(pgrep -x "${APP_EXECUTABLE_NAME}" || true)

  if ((${#matched_pids[@]} > 0)); then
    printf '%s\n' "${matched_pids[@]}"
  fi
}

if lsof -ti "tcp:${PORT}" >/dev/null; then
  status_code="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 2 "http://127.0.0.1:${PORT}/v1/standings?date=20260616" || true)"
  if [[ "${FORCE_RESTART}" == "1" || "${status_code}" != "200" ]]; then
    if [[ "${FORCE_RESTART}" == "1" ]]; then
      echo "backend already listening on port ${PORT}; restarting because FORCE_RESTART=1"
    else
      echo "backend on port ${PORT} does not expose /v1/standings; restarting"
    fi
    kill $(lsof -ti "tcp:${PORT}") 2>/dev/null || true
    sleep 0.3
  else
    echo "backend already listening on port ${PORT}"
    echo "set FORCE_RESTART=1 to restart it with the current environment"
  fi
fi

if ! lsof -ti "tcp:${PORT}" >/dev/null; then
  PORT="${PORT}" nohup "${BACKEND_DIR}/run-backend.command" > "${LOG_FILE}" 2>&1 < /dev/null &
  echo "$!" > "${PID_FILE}"
  wait_for_backend_health "$(cat "${PID_FILE}")"
  echo "backend started on port ${PORT}"
  echo "pid: $(cat "${PID_FILE}")"
  echo "log: ${LOG_FILE}"
fi

launchctl setenv KBO_LIVE_BASE_URL "http://127.0.0.1:${PORT}"

if [[ "${FORCE_RESTART}" == "1" ]]; then
  APP_PIDS="$(find_app_pids)"
  if [[ -n "${APP_PIDS}" ]]; then
    echo "stopping existing ${APP_EXECUTABLE_NAME} instances because FORCE_RESTART=1"
    kill ${APP_PIDS} >/dev/null 2>&1 || true
    sleep 0.5
    APP_PIDS="$(find_app_pids)"
    if [[ -n "${APP_PIDS}" ]]; then
      kill ${APP_PIDS} >/dev/null 2>&1 || true
      sleep 0.5
      APP_PIDS="$(find_app_pids)"
    fi
    if [[ -n "${APP_PIDS}" ]]; then
      kill -9 ${APP_PIDS} >/dev/null 2>&1 || true
      sleep 0.5
      APP_PIDS="$(find_app_pids)"
    fi
    if [[ -n "${APP_PIDS}" ]]; then
      echo "failed to stop existing BaseballLiveKR instances; stop the Xcode run/debug session and retry" >&2
      ps -p ${APP_PIDS} -o pid,ppid,stat,command >&2 || true
      exit 1
    fi
  fi
fi

open "${APP_PATH}"

echo "app launched with KBO_LIVE_BASE_URL=http://127.0.0.1:${PORT}"
echo "stop backend: kill \$(cat ${PID_FILE})"
