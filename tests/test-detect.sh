#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.github/scripts/lib/detect.sh"

PASS=0
FAIL=0

assert() {
  local desc="$1"
  local result="$2"
  local expected="$3"
  if [[ "${result}" == "${expected}" ]]; then
    echo "  PASS: ${desc}"
    (( PASS++ ))
  else
    echo "  FAIL: ${desc} (got '${result}', want '${expected}')"
    (( FAIL++ ))
  fi
}

tmpdir=$(mktemp -d)
cleanup() { rm -rf "${tmpdir}"; }
trap cleanup EXIT

echo "=== test-detect.sh ==="

# Go detection
touch "${tmpdir}/go.mod"
assert "detect Go" "$(detect_language "${tmpdir}")" "go"
detect_go "${tmpdir}"
assert "detect_go returns 0" "$?" "0"
rc=0; detect_rust "${tmpdir}" || rc=$?
assert "detect_rust returns 1 for Go dir" "${rc}" "1"
rm "${tmpdir}/go.mod"

# Rust detection
touch "${tmpdir}/Cargo.toml"
assert "detect Rust" "$(detect_language "${tmpdir}")" "rust"
detect_rust "${tmpdir}"
assert "detect_rust returns 0" "$?" "0"
rm "${tmpdir}/Cargo.toml"

# Python - pyproject.toml
touch "${tmpdir}/pyproject.toml"
assert "detect Python (pyproject.toml)" "$(detect_language "${tmpdir}")" "python"
detect_python "${tmpdir}"
assert "detect_python returns 0" "$?" "0"
rm "${tmpdir}/pyproject.toml"

# Python - setup.py
touch "${tmpdir}/setup.py"
assert "detect Python (setup.py)" "$(detect_language "${tmpdir}")" "python"
rm "${tmpdir}/setup.py"

# Node detection
touch "${tmpdir}/package.json"
assert "detect Node" "$(detect_language "${tmpdir}")" "node"
detect_node "${tmpdir}"
assert "detect_node returns 0" "$?" "0"
rm "${tmpdir}/package.json"

# Unknown
rc=0; lang=$(detect_language "${tmpdir}") || rc=$?
assert "detect unknown returns unknown" "${lang}" "unknown"
assert "detect unknown returns 1" "${rc}" "1"

# go_module_name
echo "module github.com/example/myapp" > "${tmpdir}/go.mod"
echo "" >> "${tmpdir}/go.mod"
echo "go 1.22" >> "${tmpdir}/go.mod"
assert "go_module_name" "$(go_module_name "${tmpdir}")" "github.com/example/myapp"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
