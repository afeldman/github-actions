#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/detect.sh"

test_go() {
  require_command go
  info "Running Go tests"
  go test -v -race -count=1 ./...
}

test_rust() {
  require_command cargo
  info "Running Rust tests"
  cargo test
}

test_python() {
  info "Running Python tests"
  if command -v uv &>/dev/null; then
    uv run pytest
  else
    python -m pytest
  fi
}

test_node() {
  require_command bun
  info "Running Node.js tests"
  bun install --frozen-lockfile
  bun test
}

main() {
  local lang
  lang=$(detect_language ".") || die "Cannot detect project language"
  info "Detected language: ${lang}"

  case "${lang}" in
    go)      test_go ;;
    rust)    test_rust ;;
    python)  test_python ;;
    node)    test_node ;;
    *)       die "Unsupported language: ${lang}" ;;
  esac

  info "Tests passed"
}

main "$@"
