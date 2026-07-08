#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.github/scripts/lib/common.sh"

PASS=0
FAIL=0

assert() {
  local desc="$1"
  local result="$2"
  local expected="${3:-0}"
  if [[ "${result}" == "${expected}" ]]; then
    echo "  PASS: ${desc}"
    (( PASS++ ))
  else
    echo "  FAIL: ${desc} (got '${result}', want '${expected}')"
    (( FAIL++ ))
  fi
}

echo "=== test-common.sh ==="

# info/warn/error write to stderr
out=$(info "hello" 2>&1)
assert "info contains INFO" "$(echo "${out}" | grep -c '\[INFO\]')" "1"

out=$(warn "beware" 2>&1)
assert "warn contains WARN" "$(echo "${out}" | grep -c '\[WARN\]')" "1"

out=$(error "boom" 2>&1)
assert "error contains ERROR" "$(echo "${out}" | grep -c '\[ERROR\]')" "1"

# require_env - set variable
TEST_VAR="hello"
require_env TEST_VAR
assert "require_env passes when set" "$?" "0"

# require_env - unset variable
unset MISSING_VAR
rc=0; ( require_env MISSING_VAR ) 2>/dev/null || rc=$?
assert "require_env fails when unset" "${rc}" "1"

# require_command - present
require_command bash
assert "require_command passes for bash" "$?" "0"

# require_command - missing
rc=0; ( require_command __nonexistent_cmd_xyz__ ) 2>/dev/null || rc=$?
assert "require_command fails for missing cmd" "${rc}" "1"

# output - no GITHUB_OUTPUT -> prints to stdout
unset GITHUB_OUTPUT
result=$(output my_key my_value)
assert "output prints key=value" "${result}" "OUTPUT: my_key=my_value"

# output - with GITHUB_OUTPUT
tmpfile=$(mktemp)
GITHUB_OUTPUT="${tmpfile}" output my_key my_value
assert "output writes to GITHUB_OUTPUT file" "$(cat "${tmpfile}")" "my_key=my_value"
rm -f "${tmpfile}"

# is_ci - false outside CI
unset GITHUB_ACTIONS
rc=0; is_ci || rc=$?
assert "is_ci false outside CI" "${rc}" "1"

GITHUB_ACTIONS=true
is_ci
assert "is_ci true when set" "$?" "0"
unset GITHUB_ACTIONS

# require_file - existing
tmpfile=$(mktemp)
require_file "${tmpfile}"
assert "require_file passes for existing file" "$?" "0"
rm -f "${tmpfile}"

# require_file - missing
rc=0; ( require_file "/nonexistent/path/xyz" ) 2>/dev/null || rc=$?
assert "require_file fails for missing file" "${rc}" "1"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
