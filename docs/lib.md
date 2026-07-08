# Shell Library (`lib/`)

Shared Bash functions used by composite action scripts.
Scripts source these files via `ROOT_DIR` relative to `SCRIPT_DIR`.

```
lib/
├── common.sh   — logging, env guards, GITHUB_OUTPUT helpers
├── release.sh  — GitHub Release queries via `gh`
└── artifact.sh — artifact preparation and verification
```

---

## lib/common.sh

### `require_env VAR`

Exits with error when environment variable `VAR` is unset or empty.

```bash
require_env GH_TOKEN
require_env GITHUB_REPOSITORY
```

### `require_command CMD`

Exits with error when `CMD` is not on `PATH`.

```bash
require_command gh
require_command jq
```

### `ensure_directory PATH`

Creates directory if it does not exist (`mkdir -p`).

### `output KEY VALUE`

Writes `KEY=VALUE` to `$GITHUB_OUTPUT`. No-op when `GITHUB_OUTPUT` is unset
(safe for local script execution).

```bash
output release_exists true
output tag v1.2.3
```

### `info MSG` / `warn MSG` / `error MSG` / `die MSG`

| Function | Output |
|----------|--------|
| `info` | `▶ MSG` to stdout |
| `warn` | `::warning::MSG` (GitHub Actions annotation) |
| `error` | `::error::MSG` (GitHub Actions annotation) |
| `die` | `::error::MSG` then `exit 1` |

---

## lib/release.sh

Sources `common.sh`. Requires `GH_TOKEN` and `GITHUB_REPOSITORY` in env.

### `is_tag_build REF`

Returns 0 when `REF` starts with `refs/tags/`, 1 otherwise.

```bash
is_tag_build "$GITHUB_REF" && echo "tag build"
```

### `release_tag REF`

Strips `refs/tags/` prefix and prints the tag name.

```bash
TAG=$(release_tag "$GITHUB_REF")   # e.g. v1.2.3
```

### `release_exists TAG`

Returns 0 when the GitHub Release for `TAG` exists (uses `gh release view`).

### `release_assets TAG`

Prints asset names (one per line) for the given release.

### `release_has_assets TAG`

Returns 0 when the release has at least one asset.

### `find_asset TAG PATTERN`

Prints the first asset name matching `PATTERN` (grep -E) in the release.

### `download_asset TAG PATTERN`

Downloads the matching asset into `artifact/`. Returns 1 when no asset matches.

---

## lib/artifact.sh

Sources `common.sh`.

### `prepare_artifact TYPE BINARY`

Dispatches to `prepare_go_artifact` or `prepare_python_artifact`.
Creates `artifact/` directory.

### `prepare_go_artifact BINARY`

Finds `dist/*/*linux*amd64*/<BINARY>` and copies it to `artifact/<BINARY>`.

### `prepare_python_artifact`

Copies `dist/` to `artifact/dist`.

### `find_go_binary BINARY`

Finds the Linux amd64 binary in GoReleaser's `dist/` output.

### `artifact_exists TYPE BINARY`

Returns 0 when `artifact/<binary>` (go) or `artifact/dist` (python) exists.

### `artifact_path TYPE BINARY`

Prints the artifact path without checking existence.

| Type | Path |
|------|------|
| `go` | `artifact/<binary>` |
| `python` | `artifact/dist` |
