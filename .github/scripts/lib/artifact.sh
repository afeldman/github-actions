#!/usr/bin/env bash
# lib/artifact.sh — build artifact helpers (multi-language)

# artifact_path NAME  — print canonical artifact staging path
artifact_path() {
  local name="$1"
  echo "${ARTIFACT_DIR:-dist}/${name}"
}

# artifact_exists NAME  — return 0 if artifact file exists
artifact_exists() {
  local name="$1"
  [[ -f "$(artifact_path "${name}")" ]]
}

# prepare_artifact NAME  — ensure artifact staging dir exists, return path
prepare_artifact() {
  local name="$1"
  local dir="${ARTIFACT_DIR:-dist}"

  mkdir -p "${dir}"
  echo "${dir}/${name}"
}

# --- Go ---

# find_go_binary MODULE  — print path to compiled Go binary
find_go_binary() {
  local module="$1"
  local bin="${module##*/}"

  local candidates=(
    "./${bin}"
    "./bin/${bin}"
    "${GOPATH:-${HOME}/go}/bin/${bin}"
  )

  local path
  for path in "${candidates[@]}"; do
    if [[ -x "${path}" ]]; then
      echo "${path}"
      return 0
    fi
  done

  return 1
}

# copy_go_binary SRC DEST_NAME  — copy binary to artifact dir
copy_go_binary() {
  local src="$1"
  local dest_name="$2"
  local dest
  dest=$(prepare_artifact "${dest_name}")

  cp "${src}" "${dest}"
  echo "${dest}"
}

# prepare_go_artifact MODULE OS ARCH  — build + stage Go binary
# Sets GOOS/GOARCH, builds, copies to dist/
prepare_go_artifact() {
  local module="$1"
  local os="$2"
  local arch="$3"
  local bin="${module##*/}"
  local artifact_name="${bin}_${os}_${arch}"

  [[ "${os}" == "windows" ]] && artifact_name="${artifact_name}.exe"

  GOOS="${os}" GOARCH="${arch}" go build -o "${bin}" ./...

  copy_go_binary "./${bin}" "${artifact_name}"
  rm -f "./${bin}"
}

# --- Python ---

# prepare_python_artifact NAME  — build Python wheel/sdist, stage to dist/
prepare_python_artifact() {
  local name="$1"
  local dir="${ARTIFACT_DIR:-dist}"

  mkdir -p "${dir}"

  if command -v uv &>/dev/null; then
    uv build --out-dir "${dir}"
  else
    python -m build --outdir "${dir}"
  fi
}

# --- Rust ---

# find_rust_binary NAME  — print path to compiled Rust binary
find_rust_binary() {
  local name="$1"
  local profile="${CARGO_PROFILE:-release}"
  local path="target/${profile}/${name}"

  if [[ -x "${path}" ]]; then
    echo "${path}"
    return 0
  fi

  return 1
}

# prepare_rust_artifact NAME  — copy Rust binary to dist/
prepare_rust_artifact() {
  local name="$1"
  local os="${GOOS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
  local arch="${GOARCH:-$(uname -m)}"
  local src
  src=$(find_rust_binary "${name}") || return 1

  local artifact_name="${name}_${os}_${arch}"
  copy_go_binary "${src}" "${artifact_name}"
}
