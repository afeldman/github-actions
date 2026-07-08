#!/usr/bin/env bash
# lib/common.sh — generic helpers shared across all scripts

# --- Logging ---

info() {
  echo "[INFO]  $(date -u +%H:%M:%S) $*" >&2
}

warn() {
  echo "[WARN]  $(date -u +%H:%M:%S) $*" >&2
}

error() {
  echo "[ERROR] $(date -u +%H:%M:%S) $*" >&2
}

die() {
  error "$*"
  exit 1
}

# --- Environment guards ---

# require_env VAR [VAR...]  — die if any variable is unset or empty
require_env() {
  local var
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      die "Required environment variable \$${var} is not set"
    fi
  done
}

# require_command CMD [CMD...]  — die if any binary is not in PATH
require_command() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      die "Required command not found: ${cmd}"
    fi
  done
}

# --- GitHub Actions output ---

# output KEY VALUE  — writes to GITHUB_OUTPUT when available, else prints
output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "${key}=${value}" >> "${GITHUB_OUTPUT}"
  else
    echo "OUTPUT: ${key}=${value}"
  fi
}

# --- Utility ---

# is_ci — return 0 if running inside GitHub Actions
is_ci() {
  [[ "${GITHUB_ACTIONS:-}" == "true" ]]
}

# require_file PATH  — die if file does not exist
require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    die "Required file not found: ${path}"
  fi
}
