#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/detect.sh
source "${SCRIPT_DIR}/lib/detect.sh"
# shellcheck source=lib/artifact.sh
source "${SCRIPT_DIR}/lib/artifact.sh"

build_go() {
  require_command go
  info "Building Go project (all targets)"

  local os_list=("linux" "darwin" "windows")
  local arch_list=("amd64" "arm64")
  local module
  module=$(go_module_name ".")

  info "Module: ${module}"

  local os arch
  for os in "${os_list[@]}"; do
    for arch in "${arch_list[@]}"; do
      info "  Building ${os}/${arch}"
      prepare_go_artifact "${module}" "${os}" "${arch}"
    done
  done
}

build_rust() {
  require_command cargo
  local profile="${CARGO_PROFILE:-release}"
  info "Building Rust project (profile: ${profile})"

  cargo build "--${profile}"

  local name
  name=$(grep '^name' Cargo.toml | head -1 | sed 's/name = "\(.*\)"/\1/')
  prepare_rust_artifact "${name}"
}

build_python() {
  info "Building Python project"
  prepare_python_artifact "dist"
}

build_node() {
  require_command bun
  info "Building Node.js project"

  bun install --frozen-lockfile
  bun run build

  mkdir -p dist
  if [[ -d "out" ]]; then
    cp -r out/* dist/
  fi
}

main() {
  local lang
  lang=$(detect_language ".") || die "Cannot detect project language"
  info "Detected language: ${lang}"

  case "${lang}" in
    go)      build_go ;;
    rust)    build_rust ;;
    python)  build_python ;;
    node)    build_node ;;
    *)       die "Unsupported language: ${lang}" ;;
  esac

  info "Build complete"
  output "artifact_dir" "${ARTIFACT_DIR:-dist}"
}

main "$@"
