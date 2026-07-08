#!/usr/bin/env bash

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found."
}

require_env() {

    local var="$1"

    local value
    value=$(printenv "$var" 2>/dev/null || true)

    [[ -n "$value" ]] || die "Environment variable '$var' is not set."
}

ensure_directory() {
    mkdir -p "$1"
}

info() {
    echo "▶ $*"
}

warn() {
    echo "::warning::$*"
}

error() {
    echo "::error::$*"
}

output() {

    [[ -n "${GITHUB_OUTPUT:-}" ]] || return 0

    echo "$1=$2" >> "$GITHUB_OUTPUT"
}

die() {
    error "$1"
    exit 1
}
