#!/usr/bin/env bash
# lib/detect.sh — language/ecosystem detection from repository files

# detect_language [DIR]
# Prints the detected language: go | rust | python | node | unknown
# Returns 0 on success, 1 if unknown.
detect_language() {
  local dir="${1:-.}"

  if [[ -f "${dir}/go.mod" ]]; then
    echo "go"
    return 0
  fi

  if [[ -f "${dir}/Cargo.toml" ]]; then
    echo "rust"
    return 0
  fi

  if [[ -f "${dir}/pyproject.toml" || -f "${dir}/setup.py" || -f "${dir}/setup.cfg" ]]; then
    echo "python"
    return 0
  fi

  if [[ -f "${dir}/package.json" ]]; then
    echo "node"
    return 0
  fi

  echo "unknown"
  return 1
}

# detect_go [DIR]  — return 0 if Go project
detect_go() {
  local dir="${1:-.}"
  [[ -f "${dir}/go.mod" ]]
}

# detect_rust [DIR]  — return 0 if Rust project
detect_rust() {
  local dir="${1:-.}"
  [[ -f "${dir}/Cargo.toml" ]]
}

# detect_python [DIR]  — return 0 if Python project
detect_python() {
  local dir="${1:-.}"
  [[ -f "${dir}/pyproject.toml" || -f "${dir}/setup.py" || -f "${dir}/setup.cfg" ]]
}

# detect_node [DIR]  — return 0 if Node.js project
detect_node() {
  local dir="${1:-.}"
  [[ -f "${dir}/package.json" ]]
}

# go_module_name [DIR]  — print Go module name from go.mod
go_module_name() {
  local dir="${1:-.}"
  awk '/^module / { print $2; exit }' "${dir}/go.mod"
}

# node_package_name [DIR]  — print package name from package.json
node_package_name() {
  local dir="${1:-.}"
  if command -v jq &>/dev/null; then
    jq -r '.name' "${dir}/package.json"
  else
    grep '"name"' "${dir}/package.json" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
  fi
}
