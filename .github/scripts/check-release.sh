#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/release.sh"

validate_tag_format() {
  local tag="$1"
  if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    error "Tag '${tag}' does not match semver format (vX.Y.Z or vX.Y.Z-pre)"
    return 1
  fi
  return 0
}

check_duplicate_release() {
  local tag="$1"
  require_env GITHUB_TOKEN GITHUB_REPOSITORY

  if release_exists "${tag}"; then
    error "Release for tag '${tag}' already exists"
    return 1
  fi

  info "No existing release found for '${tag}'"
  return 0
}

main() {
  if ! is_tag_build; then
    info "Not a tag build — skipping release check"
    output "is_release" "false"
    output "version" ""
    exit 0
  fi

  local tag
  tag=$(release_tag) || die "Could not determine release tag"
  info "Tag: ${tag}"

  validate_tag_format "${tag}" || die "Invalid tag format: ${tag}"
  check_duplicate_release "${tag}" || die "Duplicate release: ${tag}"

  local version="${tag#v}"
  output "is_release" "true"
  output "version" "${version}"
  output "tag" "${tag}"

  info "Release check passed — version: ${version}"
}

main "$@"
