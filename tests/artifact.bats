#!/usr/bin/env bats

load test_helper

setup() {
    source "$REPO_ROOT/lib/common.sh"
    source "$REPO_ROOT/lib/artifact.sh"
    setup_github_output

    WORK_DIR="$(mktemp -d)"
    cd "$WORK_DIR"
}

teardown() {
    teardown_github_output
    rm -rf "$WORK_DIR"
}

# ---------------------------------------------------------------------------
# artifact_path
# ---------------------------------------------------------------------------

@test "artifact_path: go returns artifact/<binary>" {
    result=$(artifact_path go myservice)
    [ "$result" = "artifact/myservice" ]
}

@test "artifact_path: python returns artifact/dist" {
    result=$(artifact_path python "")
    [ "$result" = "artifact/dist" ]
}

# ---------------------------------------------------------------------------
# artifact_exists
# ---------------------------------------------------------------------------

@test "artifact_exists: go — true when binary present" {
    mkdir -p artifact
    touch artifact/myservice
    run artifact_exists go myservice
    [ "$status" -eq 0 ]
}

@test "artifact_exists: go — false when binary missing" {
    mkdir -p artifact
    run artifact_exists go myservice
    [ "$status" -ne 0 ]
}

@test "artifact_exists: python — true when dist present" {
    mkdir -p artifact/dist
    run artifact_exists python ""
    [ "$status" -eq 0 ]
}

@test "artifact_exists: python — false when dist missing" {
    mkdir -p artifact
    run artifact_exists python ""
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# find_go_binary
# ---------------------------------------------------------------------------

@test "find_go_binary: finds binary in dist/linux_amd64 subdirectory" {
    mkdir -p dist/myservice_linux_amd64_v1
    touch dist/myservice_linux_amd64_v1/myservice
    result=$(find_go_binary myservice)
    [[ "$result" == *"linux_amd64"* ]]
    [[ "$result" == *"myservice"* ]]
}

@test "find_go_binary: returns empty when binary not in dist" {
    mkdir -p dist/myservice_linux_amd64_v1
    result=$(find_go_binary otherbinary)
    [ -z "$result" ]
}

@test "find_go_binary: returns empty when dist does not exist" {
    result=$(find_go_binary myservice)
    [ -z "$result" ]
}

# ---------------------------------------------------------------------------
# prepare_go_artifact
# ---------------------------------------------------------------------------

@test "prepare_go_artifact: copies binary to artifact/" {
    mkdir -p dist/myservice_linux_amd64_v1 artifact
    touch dist/myservice_linux_amd64_v1/myservice

    run prepare_go_artifact myservice
    [ "$status" -eq 0 ]
    [ -f "artifact/myservice" ]
}

@test "prepare_go_artifact: fails when binary not found" {
    mkdir -p dist artifact

    run prepare_go_artifact myservice
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# prepare_python_artifact
# ---------------------------------------------------------------------------

@test "prepare_python_artifact: copies dist/ to artifact/dist" {
    mkdir -p dist artifact
    touch dist/mypackage-1.0.0-py3-none-any.whl

    run prepare_python_artifact
    [ "$status" -eq 0 ]
    [ -d "artifact/dist" ]
    [ -f "artifact/dist/mypackage-1.0.0-py3-none-any.whl" ]
}

@test "prepare_python_artifact: fails when dist/ does not exist" {
    run prepare_python_artifact
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# prepare_artifact (dispatcher)
# ---------------------------------------------------------------------------

@test "prepare_artifact: dispatches to go path" {
    mkdir -p dist/myservice_linux_amd64_v1 artifact
    touch dist/myservice_linux_amd64_v1/myservice

    run prepare_artifact go myservice
    [ "$status" -eq 0 ]
}

@test "prepare_artifact: dispatches to python path" {
    mkdir -p dist
    touch dist/mypackage.whl

    run prepare_artifact python ""
    [ "$status" -eq 0 ]
}

@test "prepare_artifact: fails for unknown type" {
    run prepare_artifact ruby ""
    [ "$status" -ne 0 ]
}
