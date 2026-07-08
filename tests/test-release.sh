#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.github/scripts/lib/release.sh"

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

echo "=== test-release.sh ==="

# release_tag from GITHUB_REF
unset GIT_TAG
GITHUB_REF="refs/tags/v1.2.3"
assert "release_tag from GITHUB_REF" "$(release_tag)" "v1.2.3"

# release_tag from GIT_TAG env (local testing)
unset GITHUB_REF
GIT_TAG="v2.0.0-beta"
assert "release_tag from GIT_TAG" "$(release_tag)" "v2.0.0-beta"
unset GIT_TAG

# release_tag fails when no ref
unset GITHUB_REF GIT_TAG
( release_tag ) 2>/dev/null
assert "release_tag fails with no ref" "$?" "1"

# is_tag_build
GITHUB_REF="refs/tags/v1.0.0"
is_tag_build
assert "is_tag_build true for tag ref" "$?" "0"

GITHUB_REF="refs/heads/main"
is_tag_build
assert "is_tag_build false for branch ref" "$?" "1"

GIT_TAG="v1.0.0"
unset GITHUB_REF
is_tag_build
assert "is_tag_build true with GIT_TAG" "$?" "0"
unset GIT_TAG

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""
echo "NOTE: release_exists / release_id / find_asset require GITHUB_TOKEN."
echo "      Set GITHUB_TOKEN + GITHUB_REPOSITORY to test those functions."

[[ "${FAIL}" -eq 0 ]]
