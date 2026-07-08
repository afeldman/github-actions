#!/usr/bin/env bash
# lib/release.sh — GitHub release helpers
# Requires: GITHUB_TOKEN, GITHUB_REPOSITORY

# release_tag  — print current tag from GITHUB_REF or GIT_TAG env
release_tag() {
  if [[ -n "${GIT_TAG:-}" ]]; then
    echo "${GIT_TAG}"
    return 0
  fi

  if [[ "${GITHUB_REF:-}" == refs/tags/* ]]; then
    echo "${GITHUB_REF#refs/tags/}"
    return 0
  fi

  return 1
}

# is_tag_build  — return 0 if current ref is a tag
is_tag_build() {
  [[ "${GITHUB_REF:-}" == refs/tags/* ]] || [[ -n "${GIT_TAG:-}" ]]
}

# _gh_api PATH  — call GitHub API, print JSON response
_gh_api() {
  local path="$1"
  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com${path}"
}

# release_exists TAG  — return 0 if release for TAG already exists
release_exists() {
  local tag="$1"
  local repo="${GITHUB_REPOSITORY:?}"

  _gh_api "/repos/${repo}/releases/tags/${tag}" &>/dev/null
}

# release_id TAG  — print numeric release id for TAG, return 1 if not found
release_id() {
  local tag="$1"
  local repo="${GITHUB_REPOSITORY:?}"

  _gh_api "/repos/${repo}/releases/tags/${tag}" 2>/dev/null \
    | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2
}

# release_assets TAG  — print JSON array of assets for TAG
release_assets() {
  local tag="$1"
  local repo="${GITHUB_REPOSITORY:?}"

  local id
  id=$(release_id "${tag}") || return 1
  _gh_api "/repos/${repo}/releases/${id}/assets"
}

# release_has_assets TAG  — return 0 if release has at least one asset
release_has_assets() {
  local tag="$1"
  local assets

  assets=$(release_assets "${tag}") || return 1
  echo "${assets}" | grep -q '"id"'
}

# find_asset TAG NAME  — print download URL for asset NAME in release TAG
find_asset() {
  local tag="$1"
  local name="$2"

  release_assets "${tag}" 2>/dev/null \
    | grep -A2 "\"name\": \"${name}\"" \
    | grep '"browser_download_url"' \
    | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/'
}

# download_asset URL DEST  — download asset to DEST path
download_asset() {
  local url="$1"
  local dest="$2"

  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -L "${url}" \
    -o "${dest}"
}
