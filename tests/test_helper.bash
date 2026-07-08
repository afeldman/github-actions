REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Add a mock bin dir to PATH for tests that need to intercept external commands.
setup_mock_bin() {
    MOCK_BIN="$(mktemp -d)"
    export PATH="$MOCK_BIN:$PATH"
}

teardown_mock_bin() {
    [[ -n "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}

# Write a mock executable that echoes fixed output and exits with a given code.
mock_command() {
    local name="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"

    cat > "$MOCK_BIN/$name" <<EOF
#!/usr/bin/env bash
echo "$output"
exit $exit_code
EOF
    chmod +x "$MOCK_BIN/$name"
}

# Redirect GITHUB_OUTPUT to a temp file and export it.
setup_github_output() {
    export GITHUB_OUTPUT
    GITHUB_OUTPUT="$(mktemp)"
}

teardown_github_output() {
    [[ -n "${GITHUB_OUTPUT:-}" ]] && rm -f "$GITHUB_OUTPUT"
}

# Read a key from GITHUB_OUTPUT.
github_output_get() {
    local key="$1"
    grep "^${key}=" "$GITHUB_OUTPUT" | cut -d= -f2-
}
