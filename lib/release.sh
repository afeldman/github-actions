#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

release_tag() {

    local ref="$1"

    echo "${ref#refs/tags/}"
}

is_tag_build() {

    local ref="$1"

    [[ "$ref" == refs/tags/* ]]
}

release_exists() {

    require_command gh
    require_env GITHUB_REPOSITORY
    require_env GH_TOKEN

    local tag="$1"

    gh release view "$tag" \
        --repo "$GITHUB_REPOSITORY" \
        >/dev/null 2>&1
}

release_assets() {

    require_command gh
    require_env GITHUB_REPOSITORY
    require_env GH_TOKEN

    local tag="$1"

    gh release view "$tag" \
        --repo "$GITHUB_REPOSITORY" \
        --json assets \
        --jq '.assets[].name'
}

release_has_assets() {

    local tag="$1"

    [[ -n "$(release_assets "$tag")" ]]
}

find_asset() {

    local tag="$1"
    local pattern="$2"

    release_assets "$tag" \
        | grep -E "$pattern" \
        | head -n1 || true
}

download_asset() {

    require_command gh
    require_env GITHUB_REPOSITORY
    require_env GH_TOKEN

    local tag="$1"
    local pattern="$2"

    local asset
    asset=$(find_asset "$tag" "$pattern")

    [[ -n "$asset" ]] || return 1

    ensure_directory artifact

    gh release download "$tag" \
        --repo "$GITHUB_REPOSITORY" \
        --pattern "$asset" \
        --dir artifact

    info "Downloaded '$asset'."
}
