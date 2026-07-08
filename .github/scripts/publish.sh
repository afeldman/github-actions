#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/release.sh"

ARTIFACT_DIR="${ARTIFACT_DIR:-dist}"
RELEASE_DRAFT="${RELEASE_DRAFT:-false}"
RELEASE_PRERELEASE="${RELEASE_PRERELEASE:-false}"

create_release() {
  local tag="$1"
  local repo="${GITHUB_REPOSITORY:?}"

  info "Creating GitHub release for ${tag}"

  local body
  body=$(generate_release_notes "${tag}")

  local response
  response=$(curl -fsSL \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "https://api.github.com/repos/${repo}/releases" \
    -d "$(jq -n \
      --arg tag "${tag}" \
      --arg body "${body}" \
      --argjson draft "${RELEASE_DRAFT}" \
      --argjson pre "${RELEASE_PRERELEASE}" \
      '{tag_name: $tag, name: $tag, body: $body, draft: $draft, prerelease: $pre}'
    )")

  echo "${response}" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2
}

generate_release_notes() {
  local tag="$1"
  echo "Release ${tag}"
}

upload_asset() {
  local release_id="$1"
  local file="$2"
  local repo="${GITHUB_REPOSITORY:?}"
  local name
  name="$(basename "${file}")"

  info "  Uploading ${name}"

  curl -fsSL \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/octet-stream" \
    "https://uploads.github.com/repos/${repo}/releases/${release_id}/assets?name=${name}" \
    --data-binary "@${file}" \
    > /dev/null
}

upload_all_assets() {
  local release_id="$1"
  local dir="${ARTIFACT_DIR}"

  if [[ ! -d "${dir}" ]]; then
    warn "Artifact dir '${dir}' not found — nothing to upload"
    return 0
  fi

  local count=0
  local file
  while IFS= read -r -d '' file; do
    upload_asset "${release_id}" "${file}"
    (( count++ ))
  done < <(find "${dir}" -maxdepth 1 -type f -print0)

  info "Uploaded ${count} asset(s)"
}

main() {
  require_env GITHUB_TOKEN GITHUB_REPOSITORY
  is_tag_build || die "Not a tag build"

  local tag
  tag=$(release_tag) || die "Could not determine tag"

  if release_exists "${tag}"; then
    die "Release '${tag}' already exists — aborting to prevent overwrite"
  fi

  local release_id
  release_id=$(create_release "${tag}") || die "Failed to create release"
  info "Release id: ${release_id}"

  upload_all_assets "${release_id}"

  output "release_id" "${release_id}"
  output "tag" "${tag}"

  info "Publish complete"
}

main "$@"
