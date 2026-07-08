#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/release.sh"

require_env GH_TOKEN
require_env GITHUB_REPOSITORY
require_env TAG
require_env PATTERN

info "Downloading asset '$PATTERN' from release '$TAG'..."

if download_asset "$TAG" "$PATTERN"; then
    info "Download completed."
else
    error "No asset matching '$PATTERN' found in release '$TAG'."
    exit 1
fi
