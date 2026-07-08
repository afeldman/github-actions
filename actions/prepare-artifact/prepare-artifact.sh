#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/artifact.sh"

require_env ARTIFACT_TYPE
require_env BINARY_NAME

if prepare_artifact "$ARTIFACT_TYPE" "$BINARY_NAME"; then
    info "Artifact prepared."
else
    error "Failed to prepare artifact."
    exit 1
fi

if artifact_exists "$ARTIFACT_TYPE" "$BINARY_NAME"; then
    info "Artifact successfully created."

    output exists true
    output path "$(artifact_path "$ARTIFACT_TYPE" "$BINARY_NAME")"
else
    error "Artifact not found."

    output exists false
    exit 1
fi
