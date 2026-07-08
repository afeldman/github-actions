#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/release.sh"

require_env GH_TOKEN
require_env GITHUB_REF
require_env GITHUB_REPOSITORY

if ! is_tag_build "$GITHUB_REF"; then
    info "Not a tag build."

    output release_exists false
    exit 0
fi

TAG=$(release_tag "$GITHUB_REF")

output tag "$TAG"

if ! release_exists "$TAG"; then
    info "Release '$TAG' not found."

    output release_exists false
    exit 0
fi

if ! release_has_assets "$TAG"; then
    info "Release '$TAG' exists but contains no assets."

    output release_exists false
    exit 0
fi

info "Release '$TAG' already exists and contains assets."

output release_exists true
