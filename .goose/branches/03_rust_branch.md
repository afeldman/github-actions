# Task: feature/rust branch

## Context

Working directory: /Users/anton.feldmann/Projects/lynqtech/proj/github-actions
Language: bash, yaml
Goal: Create branch `feature/rust` with Rust build support

This repo provides reusable GitHub Actions workflows and composite actions.
Go support is on `main`. Rust is added on this branch.

Rust builds produce a single binary in `target/release/<binary_name>`.
No GoReleaser — use `cargo build --release`.

## Steps

### 1. Create branch

```bash
cd /Users/anton.feldmann/Projects/lynqtech/proj/github-actions
git checkout main
git checkout -b feature/rust
```

### 2. Extend `lib/artifact.sh` with Rust support

Current `lib/artifact.sh` content (append rust cases, do not remove existing code):

```bash
#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

prepare_artifact() {
    local type="$1"
    mkdir -p artifact

    case "$type" in
        go)
            prepare_go_artifact "$2"
            ;;
        python)
            prepare_python_artifact
            ;;
        *)
            warn "Unsupported artifact type '$type'"
            return 1
            ;;
    esac
}

prepare_go_artifact() {
    require_command cp
    local binary="$1"
    info "Preparing Go artifact"
    local file
    file="$(find_go_binary "$binary")"
    [[ -n "$file" ]] || { warn "Binary '$binary' not found."; return 1; }
    copy_go_binary "$file" "$binary"
}

prepare_python_artifact() {
    require_command cp
    info "Preparing Python artifact"
    [[ -d dist ]] || { warn "dist directory not found."; return 1; }
    cp -R dist artifact/dist
}

find_go_binary() {
    local binary="$1"
    find dist -type f -name "$binary" | grep linux_amd64 | head -n1 || true
}

copy_go_binary() {
    local file="$1"
    local binary="$2"
    cp "$file" "artifact/$binary"
}

artifact_exists() {
    local type="$1"
    local binary="$2"
    case "$type" in
        go)     [[ -f "artifact/$binary" ]] ;;
        python) [[ -d artifact/dist ]] ;;
        *)      warn "Unsupported artifact type '$type'"; return 1 ;;
    esac
}

artifact_path() {
    local type="$1"
    local binary="$2"
    case "$type" in
        go)     echo "artifact/$binary" ;;
        python) echo "artifact/dist" ;;
        *)      warn "Unsupported artifact type '$type'"; return 1 ;;
    esac
}
```

Add `rust` cases to `prepare_artifact`, `artifact_exists`, and `artifact_path`.
Add function `prepare_rust_artifact`:
- Takes binary name as argument
- Copies `target/release/<binary>` → `artifact/<binary>`
- Warn and return 1 if source binary not found

Rust artifact path: `artifact/<binary_name>` (same as Go)

### 3. Create `actions/setup-rust/action.yml`

Model after `actions/setup-go/action.yml`:

```yaml
name: "Setup Go"
description: "Setup Go and configure private Go modules."
inputs:
  go_version:
    description: "Go version"
    required: false
    default: ""
  go_version_file:
    description: "Path to go.mod file"
    required: false
    default: "go.mod"
runs:
  using: composite
  steps:
    - name: Setup Go
      if: ${{ inputs.go_version != '' }}
      uses: actions/setup-go@v5
      with:
        go-version: ${{ inputs.go_version }}
    - name: Setup Go from go.mod
      if: ${{ inputs.go_version == '' }}
      uses: actions/setup-go@v5
      with:
        go-version-file: ${{ inputs.go_version_file }}
```

Write `actions/setup-rust/action.yml` with:
- input `rust_version` (optional, default `stable`)
- input `target` (optional, default `x86_64-unknown-linux-gnu`)
- input `components` (optional, default `clippy,rustfmt`)
- Step: install toolchain via `dtolnay/rust-toolchain@master` with `toolchain: ${{ inputs.rust_version }}`, `targets: ${{ inputs.target }}`, `components: ${{ inputs.components }}`
- Step: cache cargo registry via `actions/cache@v4` — key `cargo-${{ runner.os }}-${{ hashFiles('**/Cargo.lock') }}`, paths `~/.cargo/registry`, `~/.cargo/git`, `target`

### 4. Create `.github/workflows/rust-build.yml`

Adapt the pattern below for Rust (cargo build --release, no GoReleaser):

```yaml
# Pattern from go-build.yml (stripped)
on:
  workflow_call:
    secrets:
      git_token:
        required: false
    inputs:
      binary_name:
        required: true
        type: string
      enable:
        default: true
        type: boolean
      only_on_tag:
        default: false
        type: boolean
    outputs:
      artifact_created:
        value: ${{ jobs.goreleaser-build.outputs.artifact_created }}

jobs:
  goreleaser-build:
    runs-on: ubuntu-latest
    if: ${{ inputs.enable && ( !inputs.only_on_tag || startsWith(github.ref, 'refs/tags/') ) }}
    outputs:
      artifact_created: ${{ steps.check.outputs.exists }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          fetch-tags: true
          token: ${{ secrets.git_token || github.token }}
      - name: Configure HTTPS for private modules
        run: git config --global url."https://${GIT_TOKEN}:@github.com/".insteadOf "https://github.com/"
        env:
          GIT_TOKEN: ${{ secrets.git_token || github.token }}
      - id: release_check
        uses: afeldman/github-actions/actions/check-release@main
      - if: steps.release_check.outputs.release_exists == 'true'
        uses: afeldman/github-actions/actions/download-release@main
        with:
          tag: ${{ steps.release_check.outputs.tag }}
          pattern: ${{ inputs.binary_name }}
      - id: prepare
        if: steps.release_check.outputs.release_exists != 'true'
        uses: afeldman/github-actions/actions/prepare-artifact@main
        with:
          artifact_type: go
          binary_name: ${{ inputs.binary_name }}
      - id: check
        run: |
          if [ -f "artifact/${{ inputs.binary_name }}" ]; then
            echo "exists=true" >> "${GITHUB_OUTPUT}"
          else
            echo "exists=false" >> "${GITHUB_OUTPUT}"
          fi
      - if: steps.check.outputs.exists == 'true'
        uses: actions/upload-artifact@v4
        with:
          name: artifact-${{ github.sha }}-build
          path: artifact/${{ inputs.binary_name }}
          retention-days: 7
```

Write `.github/workflows/rust-build.yml` for Rust:
- Name: `"Rust Build Artifact"`
- Job: `rust-build`
- inputs: `binary_name` (string, required), `rust_version` (optional string, default `stable`), `target` (optional string, default `x86_64-unknown-linux-gnu`), `cargo_extra_args` (optional string, default `""`), `enable` (bool, default true), `only_on_tag` (bool, default false)
- Setup: `afeldman/github-actions/actions/setup-rust@feature/rust` with `rust_version` and `target`
- Build: `cargo build --release ${{ inputs.cargo_extra_args }}` — only if `release_exists != 'true'`
- Prepare: `afeldman/github-actions/actions/prepare-artifact@feature/rust` with `artifact_type: rust`, `binary_name: ${{ inputs.binary_name }}`
- Check: `artifact/${{ inputs.binary_name }}` file exists → `exists=true`
- Upload: `artifact/${{ inputs.binary_name }}`
- check-release and download-release use `@main` ref (those actions are already on main)

### 5. Commit

```bash
git add lib/artifact.sh actions/setup-rust/ .github/workflows/rust-build.yml
git commit -m "feat(rust): add setup-rust action and rust-build workflow"
```

## Do NOT touch

- `actions/setup-go/`
- `.github/workflows/go-build.yml`
- `main` branch content
- Any existing tests

## Done when

- Branch `feature/rust` exists with 1 new commit
- `lib/artifact.sh` contains `prepare_rust_artifact` and `rust` cases in `artifact_exists`/`artifact_path`
- `actions/setup-rust/action.yml` exists and is valid YAML
- `.github/workflows/rust-build.yml` exists and is valid YAML
