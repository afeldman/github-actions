# Task: feature/python branch

## Context

Working directory: /Users/anton.feldmann/Projects/lynqtech/proj/github-actions
Language: bash, yaml
Goal: Create branch `feature/python` with Python build support

This repo provides reusable GitHub Actions workflows and composite actions.
Go support is on `main`. Python is added on this branch.

## Steps

### 1. Create branch

```bash
cd /Users/anton.feldmann/Projects/lynqtech/proj/github-actions
git checkout main
git checkout -b feature/python
```

### 2. Create `actions/setup-python/action.yml`

Model it after `actions/setup-go/action.yml` (see below).
Use `astral-sh/setup-uv@v6` for uv setup, then optionally pin Python version.

```yaml
# Reference — actions/setup-go/action.yml
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

Write `actions/setup-python/action.yml` with:
- input `python_version` (optional, default `""`)
- input `python_version_file` (optional, default `pyproject.toml`)
- Step: install uv via `astral-sh/setup-uv@v6`
- Step: pin Python version if `python_version != ''`, else read from `python_version_file`

### 3. Create `.github/workflows/python-build.yml`

Model it after this stripped-down Go workflow pattern:

```yaml
name: "GoReleaser Build Artifact"

on:
  workflow_call:
    secrets:
      git_token:
        required: false
    inputs:
      binary_name:
        description: "Name of the binary"
        required: true
        type: string
      enable:
        description: "Enable build"
        required: false
        default: true
        type: boolean
      only_on_tag:
        description: "Run only on git tags"
        required: false
        default: false
        type: boolean

    outputs:
      artifact_created:
        description: "Whether artifact was created"
        value: ${{ jobs.python-build.outputs.artifact_created }}

jobs:
  goreleaser-build:
    name: "Build with GoReleaser"
    runs-on: ubuntu-latest
    if: ${{ inputs.enable && ( !inputs.only_on_tag || startsWith(github.ref, 'refs/tags/') ) }}
    outputs:
      artifact_created: ${{ steps.check.outputs.exists }}
    steps:
      - name: "Checkout Code"
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          fetch-tags: true
          token: ${{ secrets.git_token || github.token }}

      - name: "Fetch tags"
        run: git fetch --tags --force

      - name: "Configure HTTPS for private modules"
        run: |
          git config --global url."https://${GIT_TOKEN}:@github.com/".insteadOf "https://github.com/"
        env:
          GIT_TOKEN: ${{ secrets.git_token || github.token }}

      - name: "Check if GitHub Release exists"
        id: release_check
        uses: afeldman/github-actions/actions/check-release@main

      - name: "Download binary from existing release"
        if: steps.release_check.outputs.release_exists == 'true'
        uses: afeldman/github-actions/actions/download-release@main
        with:
          tag: ${{ steps.release_check.outputs.tag }}
          pattern: ${{ inputs.binary_name }}

      - name: "Run GoReleaser build"
        if: steps.release_check.outputs.release_exists != 'true'
        uses: goreleaser/goreleaser-action@f06c13b6b1a9625abc9e6e439d9c05a8f2190e94 # v7
        with:
          version: "~> v2"
          args: build --clean ${{ inputs.goreleaser_extra_args }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: "Prepare artifact"
        id: prepare
        if: steps.release_check.outputs.release_exists != 'true'
        uses: afeldman/github-actions/actions/prepare-artifact@main
        with:
          artifact_type: go
          binary_name: ${{ inputs.binary_name }}

      - name: "Check artifact exists"
        id: check
        run: |
          if [ -f "artifact/${{ inputs.binary_name }}" ]; then
            echo "exists=true" >> "${GITHUB_OUTPUT}"
          else
            echo "exists=false" >> "${GITHUB_OUTPUT}"
          fi

      - name: "Upload artifact"
        if: steps.check.outputs.exists == 'true'
        uses: actions/upload-artifact@v4
        with:
          name: artifact-${{ github.sha }}-build
          path: artifact/${{ inputs.binary_name }}
          retention-days: 7
```

Write `.github/workflows/python-build.yml` adapted for Python:
- Name: `"Python Build Artifact"`
- Job name: `python-build`
- No `binary_name` input (Python packages don't have a single binary name). Use `package_name` instead for artifact naming.
- inputs: `python_version` (optional), `enable` (bool, default true), `only_on_tag` (bool, default false)
- Setup step: use `afeldman/github-actions/actions/setup-python@feature/python`
- Build step: run `uv build` — produces `dist/`
- Prepare artifact: use `afeldman/github-actions/actions/prepare-artifact@feature/python` with `artifact_type: python`
- Check artifact: check `artifact/dist` directory exists
- Upload artifact: upload `artifact/dist`
- Output: `artifact_created`
- Use `check-release` and `download-release` with `pattern: ${{ inputs.package_name }}` for the skip-if-exists logic (same as Go)

### 4. Verify `lib/artifact.sh` has Python support

`lib/artifact.sh` already contains `prepare_python_artifact` and python cases in `artifact_exists` / `artifact_path`. Do NOT modify it.

### 5. Commit

```bash
git add actions/setup-python/ .github/workflows/python-build.yml
git commit -m "feat(python): add setup-python action and python-build workflow"
```

## Do NOT touch

- `lib/artifact.sh` (python support already exists)
- `actions/setup-go/`
- `.github/workflows/go-build.yml`
- `main` branch content
- Any existing tests

## Done when

- Branch `feature/python` exists
- `actions/setup-python/action.yml` exists and is valid YAML
- `.github/workflows/python-build.yml` exists and is valid YAML
- Git commit exists on `feature/python`
