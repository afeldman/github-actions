# Task: feature/node branch

## Context

Working directory: /Users/anton.feldmann/Projects/lynqtech/proj/github-actions
Language: bash, yaml
Goal: Create branch `feature/node` with Node.js build support

This repo provides reusable GitHub Actions workflows and composite actions.
Go support is on `main`. Node.js is added on this branch.

Package manager preference: yarn (primary) or bun. NOT npm.

## Steps

### 1. Create branch

```bash
cd /Users/anton.feldmann/Projects/lynqtech/proj/github-actions
git checkout main
git checkout -b feature/node
```

### 2. Extend `lib/artifact.sh` with Node support

Current `lib/artifact.sh` content (you MUST append node cases, do not remove existing code):

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
        go)   [[ -f "artifact/$binary" ]] ;;
        python) [[ -d artifact/dist ]] ;;
        *)    warn "Unsupported artifact type '$type'"; return 1 ;;
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

Add `node` cases to `prepare_artifact`, `artifact_exists`, and `artifact_path`.
Add function `prepare_node_artifact`:
- Copies `dist/` → `artifact/dist` (same as python)
- Warn and return 1 if `dist/` does not exist

Node artifact path: `artifact/dist`

### 3. Create `actions/setup-node/action.yml`

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
  go_private:
    description: "GOPRIVATE value"
    required: false
    default: ""
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
    - name: Configure GOPRIVATE
      shell: bash
      run: |
        go env -w GOPRIVATE="${{ inputs.go_private }}"
```

Write `actions/setup-node/action.yml` with:
- input `node_version` (optional, default `""`)
- input `node_version_file` (optional, default `.node-version`, fallback `.nvmrc`)
- input `package_manager` (optional, default `yarn`, values: `yarn|bun|npm`)
- Step: `actions/setup-node@v4` — if `node_version != ''` use `node-version: ${{ inputs.node_version }}`, else use `node-version-file: ${{ inputs.node_version_file }}`
- Step: install package manager if `bun` — `npm install -g bun`
- Step: install dependencies — run `${{ inputs.package_manager }} install` (shell: bash)

### 4. Create `.github/workflows/node-build.yml`

Adapt the Go workflow pattern below for Node:

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

Write `.github/workflows/node-build.yml` for Node:
- Name: `"Node.js Build Artifact"`
- Job: `node-build`
- inputs: `package_name` (string, required — used for artifact naming and download pattern), `node_version` (optional string), `package_manager` (optional string, default `yarn`), `build_command` (optional string, default `build`), `enable` (bool, default true), `only_on_tag` (bool, default false)
- Setup: `afeldman/github-actions/actions/setup-node@feature/node` with `node_version` and `package_manager`
- Build: run `${{ inputs.package_manager }} run ${{ inputs.build_command }}` — only if `release_exists != 'true'`
- Prepare: `afeldman/github-actions/actions/prepare-artifact@feature/node` with `artifact_type: node`
- Check: `artifact/dist` directory exists → `exists=true`
- Upload: `artifact/dist`

### 5. Commit

```bash
git add lib/artifact.sh actions/setup-node/ .github/workflows/node-build.yml
git commit -m "feat(node): add setup-node action and node-build workflow"
```

## Do NOT touch

- `actions/setup-go/`
- `.github/workflows/go-build.yml`
- `main` branch content
- Any existing tests

## Done when

- Branch `feature/node` exists with 1 new commit
- `lib/artifact.sh` contains `prepare_node_artifact` and `node` cases in `artifact_exists`/`artifact_path`
- `actions/setup-node/action.yml` exists and is valid YAML
- `.github/workflows/node-build.yml` exists and is valid YAML
