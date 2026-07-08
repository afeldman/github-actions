# goreleaser-build Workflow

Reusable workflow: builds a Go binary (or Python artifact) via GoReleaser, or downloads
an existing binary from a GitHub Release if one already exists for the current tag.

## Usage

```yaml
jobs:
  build:
    uses: enercity/github-actions-datalynx/.github/workflows/goreleaser-build.yml@main
    with:
      binary_name: myservice
    secrets:
      git_token: ${{ secrets.READ_ACCESS_TO_ALL_ENERCITY_REPOS }}
```

## Flow

```
tag build?
  ├─ yes → release with assets exists?
  │           ├─ yes → download binary from release  (skip build)
  │           └─ no  → run goreleaser build
  └─ no  → run goreleaser build (snapshot / branch)
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `binary_name` | ✅ | — | Binary name to build or download |
| `go_version` | | *(from `go.mod`)* | Go version; empty = auto-detect from `go.mod` |
| `build_path` | | `.` | Path to Go module root |
| `artifact_type` | | `go` | `go` or `python` |
| `enable` | | `true` | Set `false` to skip the whole job |
| `only_on_tag` | | `false` | `true` = run only on `refs/tags/*` |
| `goreleaser_extra_args` | | `` | Extra args passed to `goreleaser build` (e.g. `--snapshot`) |

## Secrets

| Secret | Description |
|--------|-------------|
| `ssh_private_key` | SSH key for private Go modules |
| `git_token` | GitHub token for private modules (HTTPS fallback) |

## Outputs

| Output | Description |
|--------|-------------|
| `artifact_created` | `true` when artifact was built or downloaded successfully |

## Composite Actions Used

| Action | Purpose |
|--------|---------|
| `actions/setup-go` | Setup Go + configure `GOPRIVATE` |
| `actions/check-release` | Detect existing GitHub Release with assets |
| `actions/download-release` | Download asset from an existing release |
| `actions/prepare-artifact` | Copy built binary from `dist/` into `artifact/` |

See [actions.md](actions.md) for full action reference.
