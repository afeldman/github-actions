#!/usr/bin/env bats

load test_helper

setup() {
    source "$REPO_ROOT/lib/common.sh"
    source "$REPO_ROOT/lib/release.sh"
    setup_mock_bin
    setup_github_output
    export GITHUB_REPOSITORY="enercity/test-repo"
    export GH_TOKEN="fake-token"
}

teardown() {
    teardown_mock_bin
    teardown_github_output
}

# ---------------------------------------------------------------------------
# is_tag_build
# ---------------------------------------------------------------------------

@test "is_tag_build: true for refs/tags/v1.2.3" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; source '$REPO_ROOT/lib/release.sh'; is_tag_build 'refs/tags/v1.2.3'"
    [ "$status" -eq 0 ]
}

@test "is_tag_build: true for refs/tags/release-1.0" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; source '$REPO_ROOT/lib/release.sh'; is_tag_build 'refs/tags/release-1.0'"
    [ "$status" -eq 0 ]
}

@test "is_tag_build: false for refs/heads/main" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; source '$REPO_ROOT/lib/release.sh'; is_tag_build 'refs/heads/main'"
    [ "$status" -ne 0 ]
}

@test "is_tag_build: false for refs/heads/feature/foo" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; source '$REPO_ROOT/lib/release.sh'; is_tag_build 'refs/heads/feature/foo'"
    [ "$status" -ne 0 ]
}

@test "is_tag_build: false for empty string" {
    run bash -c "source '$REPO_ROOT/lib/common.sh'; source '$REPO_ROOT/lib/release.sh'; is_tag_build ''"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# release_tag
# ---------------------------------------------------------------------------

@test "release_tag: strips refs/tags/ prefix" {
    result=$(release_tag "refs/tags/v1.2.3")
    [ "$result" = "v1.2.3" ]
}

@test "release_tag: works with pre-release tags" {
    result=$(release_tag "refs/tags/v2.0.0-rc1")
    [ "$result" = "v2.0.0-rc1" ]
}

@test "release_tag: returns full string when no refs/tags/ prefix" {
    result=$(release_tag "v1.0.0")
    [ "$result" = "v1.0.0" ]
}

# ---------------------------------------------------------------------------
# release_exists (mocked gh)
# ---------------------------------------------------------------------------

@test "release_exists: true when gh release view succeeds" {
    mock_command gh 0 ""
    run release_exists "v1.0.0"
    [ "$status" -eq 0 ]
}

@test "release_exists: false when gh release view fails" {
    mock_command gh 1 ""
    run release_exists "v999.0.0"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# release_assets / release_has_assets (mocked gh)
# ---------------------------------------------------------------------------

@test "release_assets: returns asset list from gh output" {
    mock_command gh 0 "myservice_linux_amd64"
    result=$(release_assets "v1.0.0")
    [ "$result" = "myservice_linux_amd64" ]
}

@test "release_has_assets: true when assets present" {
    mock_command gh 0 "myservice_linux_amd64"
    run release_has_assets "v1.0.0"
    [ "$status" -eq 0 ]
}

@test "release_has_assets: false when no assets" {
    mock_command gh 0 ""
    run release_has_assets "v1.0.0"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# find_asset (mocked gh)
# ---------------------------------------------------------------------------

@test "find_asset: returns first matching asset" {
    mock_command gh 0 "myservice_linux_amd64
myservice_darwin_amd64
checksums.txt"
    result=$(find_asset "v1.0.0" "linux_amd64")
    [ "$result" = "myservice_linux_amd64" ]
}

@test "find_asset: returns empty when no match" {
    mock_command gh 0 "myservice_darwin_amd64
checksums.txt"
    result=$(find_asset "v1.0.0" "linux_amd64")
    [ -z "$result" ]
}
