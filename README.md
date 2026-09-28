# devcontainer-base

The base image of the classroom and development images: devcontainer-core plus
Go, Node.js, Deno, Prettier and the VS Code Server, with a shared VS Code
configuration.

**Image:** `ghcr.io/majikmate/devcontainer-base:2` · linux/amd64, linux/arm64 ·
[release notes](https://github.com/majikmate/devcontainer-base/releases)

## Dependencies

```text
                                               Nightly Content
devcontainer-features                                  Go library of layers, compiled into devcon
  ▼
devcontainer-core:1                            22:17   Debian 13, devcon, user dev, zsh, SSH server
├── devcontainer-base:2                        23:17   + go, build-tools, node, deno, prettier, vscode-server
│   ├── devcontainer-dev:2                     23:57   + github-cli
│   ├── devcontainer-classroom-web:2           00:07   classroom settings, AI off
│   └── devcontainer-classroom-web-advanced:2  00:17   + playwright-deps, AI on
└── devcontainer-classroom-exam-ts:2           23:47   + deno, AI and coding assistance off
```

This repository: **devcontainer-base**. Nightly checks in UTC. Repositories:
[core](https://github.com/majikmate/devcontainer-core) ·
[features](https://github.com/majikmate/devcontainer-features) ·
[base](https://github.com/majikmate/devcontainer-base) ·
[dev](https://github.com/majikmate/devcontainer-dev) ·
[classroom-web](https://github.com/majikmate/devcontainer-classroom-web) ·
[classroom-web-advanced](https://github.com/majikmate/devcontainer-classroom-web-advanced) ·
[classroom-exam-ts](https://github.com/majikmate/devcontainer-classroom-exam-ts)

## Use

Build an image on this base in `.devcontainer/Dockerfile` and add layers:

```dockerfile
FROM ghcr.io/majikmate/devcontainer-base:2

ARG GITHUB_CLI_VERSION
RUN devcon install github-cli
```

- `:2` receives all compatible updates (new tool versions, security updates).
- A full version (for example `:2.0.8`) stays available for at least 90 days.
- See [Writing an image](https://github.com/majikmate/devcontainer-core#writing-an-image).

## Content

Each layer is one line in [`.devcontainer/Dockerfile`](.devcontainer/Dockerfile):

| Layer | Content | Version |
| ----- | ------- | ------- |
| (devcontainer-core) | Debian 13, user `dev`, zsh, locales, git settings, aliases, Pure prompt, SSH server on port 2222 | see [core](https://github.com/majikmate/devcontainer-core#content); Debian release: [`debianPin`](https://github.com/majikmate/devcontainer-core/blob/main/pkg/layers/os.go#L31-L34) |
| `go` | Go, gopls, dlv, staticcheck, govulncheck, golangci-lint | Go 1.27.x; the Go tools in the newest version that works with this Go ([`goPin`](https://github.com/majikmate/devcontainer-features/blob/main/golang/golang.go#L49-L54)) |
| `build-tools` | make, gcc, g++, python3 (for native npm modules) | Debian packages of the Debian release ([`debianPin`](https://github.com/majikmate/devcontainer-core/blob/main/pkg/layers/os.go#L31-L34)) |
| `node` | nvm, Node.js, npm (no pnpm, no yarn) | Node.js 24.x LTS ([`nodePin`, `nodeChannel`](https://github.com/majikmate/devcontainer-features/blob/main/node/node.go#L39-L44)) |
| `deno` | Deno | Deno 2.x LTS, the release of `deno upgrade lts` ([`denoPin`, `denoChannel`](https://github.com/majikmate/devcontainer-features/blob/main/deno/deno.go#L36-L39)) |
| `prettier` | Prettier with `prettier-plugin-tailwindcss`, global configuration `/.prettierrc.json` | newest release ([`prettierPin`](https://github.com/majikmate/devcontainer-features/blob/main/prettier/prettier.go#L32-L37)) |
| `vscode-server` | VS Code Server in `~/.vscode-server` of the user `dev`: the Dev Containers extension of the same VS Code release starts it without a download | newest VS Code release ([`vscodeServerPin`](https://github.com/majikmate/devcontainer-features/blob/main/vscodeserver/vscodeserver.go#L38-L41)) |

**Versions:** the features decide the pinned lines and channels, not this
Dockerfile ([rules](https://github.com/majikmate/devcontainer-features#versions)).
When a pinned line reaches its end of life, the nightly check and the build
fail and name the supported lines.
Details of all layers:
[docs/layers.md](https://github.com/majikmate/devcontainer-core/blob/main/docs/layers.md).

## VS Code

- **Extensions:** Go, Deno, Prettier, Markdown preview (from the layers),
  PlantUML (from [`devcontainer.json`](.devcontainer/devcontainer.json)).
- **Formatting:** Prettier is the only formatter, with the standard Prettier
  style, format on save and 2 spaces. Tailwind CSS classes are sorted. A
  project with its own Prettier configuration uses that configuration. Go uses
  `gofmt`; PlantUML files are not formatted.
- **Deno** is the JavaScript/TypeScript runtime and language server, not the
  formatter.
- **SSH:** port 2222, keys of your GitHub account only
  ([SSH access](https://github.com/majikmate/devcontainer-core#ssh-access)).

## Releases

- **Nightly check at 23:17 UTC** (01:17 CEST). A new version is released when an input
  changes: `.devcontainer`, `README.md`, the digest of `devcontainer-core:1`, or the
  version of a tool (see Versions). Pending Debian updates and an age
  above 7 days also lead to a new version.
- **Version step:** patch; minor when Go 1.x or the major version of Node.js
  or Deno changes.
- **Manual:** **Actions → Release → Run workflow**. The option `upstream` (on
  by default) first updates core; `force` releases without a change.
- **Pull requests** build and test both architectures and publish nothing.
- **Kept versions:** the newest release and the tags `2`, `2.x` and `latest`.
  Older releases and workflow runs are deleted after 90 days. **Actions →
  Prune** lists or deletes them at once; the scope `all-but-newest` keeps
  only the newest release and the newest run of each workflow.

Rules: [Releases](https://github.com/majikmate/devcontainer-core#releases).

## Change the image

Change `.devcontainer/` or `README.md` through a pull request. After the merge,
the new image is released automatically (GitHub shows the README of the newest
image on the package page).

---

© 2026 Hannes Stauss (scalarion@nimblescape.com) · [MIT License](LICENSE).
