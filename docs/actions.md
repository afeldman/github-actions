# Composite Actions

Composite actions live in `actions/<name>/action.yml`.
Shell scripts in the same directory source shared helpers from `lib/`.

## actions/setup-go

Setup Go and configure `GOPRIVATE` for private modules.

**Inputs**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `go_version` | | `` | Explicit Go version; empty = read from `go.mod` |
| `go_private` | | `github.com/enercity` | `GOPRIVATE` value |

**Usage**

```yaml
- uses: enercity/github-actions-datalynx/actions/setup-go@main
  with:
    go_version: "1.22"
```

---

## actions/check-release

Check whether a GitHub Release exists for the current tag and contains assets.
Reads `GITHUB_REF` to determine the tag. On branch builds: outputs `release_exists=false`
and exits without error.

**Env (auto-injected from `github.*`)**

| Var | Source |
|-----|--------|
| `GH_TOKEN` | `github.token` |
| `GITHUB_REF` | `github.ref` |
| `GITHUB_REPOSITORY` | `github.repository` |

**Outputs**

| Output | Description |
|--------|-------------|
| `tag` | Release tag (e.g. `v1.2.3`) |
| `release_exists` | `true` when release exists and has assets |

**Usage**

```yaml
- id: release_check
  uses: enercity/github-actions-datalynx/actions/check-release@main
```

---

## actions/download-release

Download a named asset from an existing GitHub Release into `artifact/`.

**Inputs**

| Input | Required | Description |
|-------|----------|-------------|
| `tag` | ✅ | Release tag to download from |
| `pattern` | ✅ | Asset name or grep-compatible pattern |

**Usage**

```yaml
- uses: enercity/github-actions-datalynx/actions/download-release@main
  with:
    tag: ${{ steps.release_check.outputs.tag }}
    pattern: myservice
```

---

## actions/prepare-artifact

Copy a built binary from GoReleaser's `dist/` output into `artifact/` for upload.
For Python: copies the `dist/` directory.

**Inputs**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact_type` | | `go` | `go` or `python` |
| `binary_name` | | `` | Go binary name (ignored for Python) |

**Outputs**

| Output | Description |
|--------|-------------|
| `exists` | `true` when artifact was successfully prepared |
| `path` | Path to the artifact (`artifact/<binary>` or `artifact/dist`) |

**Usage**

```yaml
- id: prepare
  uses: enercity/github-actions-datalynx/actions/prepare-artifact@main
  with:
    artifact_type: go
    binary_name: myservice
```
