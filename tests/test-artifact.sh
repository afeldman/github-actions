#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.github/scripts/lib/artifact.sh"

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

export ARTIFACT_DIR="${tmpdir}/dist"

echo "=== test-artifact.sh ==="

# artifact_path
assert "artifact_path" "$(artifact_path "mybin")" "${tmpdir}/dist/mybin"

# artifact_exists - missing
rc=0; artifact_exists "mybin" || rc=$?
assert "artifact_exists false before create" "${rc}" "1"

# prepare_artifact - creates dir, returns path
result=$(prepare_artifact "mybin")
assert "prepare_artifact returns path" "${result}" "${tmpdir}/dist/mybin"
assert "prepare_artifact creates dir" "$([ -d "${tmpdir}/dist" ] && echo yes)" "yes"

# artifact_exists - after touch
touch "${tmpdir}/dist/mybin"
artifact_exists "mybin"
assert "artifact_exists true after create" "$?" "0"

# copy_go_binary
fake_bin="${tmpdir}/fake_bin"
printf '#!/bin/sh\necho hi\n' > "${fake_bin}"
chmod +x "${fake_bin}"

dest=$(copy_go_binary "${fake_bin}" "myapp_linux_amd64")
assert "copy_go_binary returns dest" "${dest}" "${tmpdir}/dist/myapp_linux_amd64"
assert "copy_go_binary file exists" "$([ -f "${dest}" ] && echo yes)" "yes"

# find_go_binary - present in ./bin/
mkdir -p "${tmpdir}/bin"
touch "${tmpdir}/bin/mytool"
chmod +x "${tmpdir}/bin/mytool"

(
  cd "${tmpdir}"
  result=$(find_go_binary "github.com/example/mytool")
  [[ "${result}" == "./bin/mytool" ]]
)
assert "find_go_binary finds ./bin/mytool" "$?" "0"

# find_go_binary - not found
rc=0; ( find_go_binary "github.com/example/nonexistent" ) 2>/dev/null || rc=$?
assert "find_go_binary returns 1 when missing" "${rc}" "1"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
