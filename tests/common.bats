#!/usr/bin/env bats

load test_helper

setup() {
    source "$REPO_ROOT/lib/common.sh"
    setup_github_output
}

teardown() {
    teardown_github_output
}

# ---------------------------------------------------------------------------
# require_env
# ---------------------------------------------------------------------------

@test "require_env: passes when var is set" {
    MY_VAR="hello" run bash -c "source '$REPO_ROOT/lib/common.sh'; require_env MY_VAR"
    [ "$status" -eq 0 ]
}

@test "require_env: fails when var is unset" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; unset MISSING_VAR; require_env MISSING_VAR"
    [ "$status" -ne 0 ]
}

@test "require_env: fails when var is empty" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; EMPTY_VAR=''; require_env EMPTY_VAR"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# output
# ---------------------------------------------------------------------------

@test "output: writes key=value to GITHUB_OUTPUT" {
    output release_exists true
    [ "$(github_output_get release_exists)" = "true" ]
}

@test "output: writes multiple keys" {
    output tag v1.2.3
    output release_exists true
    [ "$(github_output_get tag)" = "v1.2.3" ]
    [ "$(github_output_get release_exists)" = "true" ]
}

@test "output: no-op when GITHUB_OUTPUT is unset" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; unset GITHUB_OUTPUT; output key value"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# info / warn / error / die
# ---------------------------------------------------------------------------

@test "info: prints with arrow prefix" {
    run info "hello world"
    [ "$output" = "▶ hello world" ]
}

@test "warn: prints GitHub Actions warning annotation" {
    run warn "something fishy"
    [ "$output" = "::warning::something fishy" ]
}

@test "error: prints GitHub Actions error annotation" {
    run error "it broke"
    [ "$output" = "::error::it broke" ]
}

@test "die: exits non-zero" {
    run die "fatal error"
    [ "$status" -ne 0 ]
}

@test "die: prints error annotation" {
    run die "fatal error"
    [[ "$output" == *"::error::fatal error"* ]]
}

# ---------------------------------------------------------------------------
# require_command
# ---------------------------------------------------------------------------

@test "require_command: passes for existing command" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; require_command bash"
    [ "$status" -eq 0 ]
}

@test "require_command: fails for missing command" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; require_command __nonexistent_cmd_xyz__"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ensure_directory
# ---------------------------------------------------------------------------

@test "ensure_directory: creates directory" {
    local dir
    dir="$(mktemp -d)/subdir/nested"
    ensure_directory "$dir"
    [ -d "$dir" ]
    rm -rf "$(dirname "$(dirname "$dir")")"
}
