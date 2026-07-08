#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/detect.sh"

lint_go() {
  require_command go
  info "Running Go vet"
  go vet ./...

  if command -v golangci-lint &>/dev/null; then
    info "Running golangci-lint"
    golangci-lint run ./...
  else
    warn "golangci-lint not found, skipping extended lint"
  fi
}

lint_rust() {
  require_command cargo
  info "Running cargo clippy"
  cargo clippy -- -D warnings

  info "Checking formatting"
  cargo fmt --check
}

lint_python() {
  info "Running Python linters"
  if command -v uv &>/dev/null; then
    uv run ruff check .
    uv run ruff format --check .
  elif command -v ruff &>/dev/null; then
    ruff check .
    ruff format --check .
  else
    warn "ruff not found, skipping Python lint"
  fi
}

lint_node() {
  require_command bun
  info "Running Node.js lint"
  bun install --frozen-lockfile

  if [[ -f "package.json" ]] && grep -q '"lint"' package.json; then
    bun run lint
  else
    warn "No lint script in package.json, skipping"
  fi
}

main() {
  local lang
  lang=$(detect_language ".") || die "Cannot detect project language"
  info "Detected language: ${lang}"

  case "${lang}" in
    go)      lint_go ;;
    rust)    lint_rust ;;
    python)  lint_python ;;
    node)    lint_node ;;
    *)       die "Unsupported language: ${lang}" ;;
  esac

  info "Lint passed"
}

main "$@"
