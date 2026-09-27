# Dev Container Base

The base [Dev Container](https://containers.dev/) image for the majikmate
classroom and development environments. It adds Go, Node.js, Deno and Prettier
to [devcontainer-core](https://github.com/majikmate/devcontainer-core)
(Debian 13 "trixie", user `dev`, zsh, SSH server), and a shared VS Code
configuration.

Published image: `ghcr.io/majikmate/devcontainer-base` (linux/amd64 and
linux/arm64)

## Images and their dependencies

```
devcontainer-core                         (Debian 13, user dev, zsh, locales, git, Pure prompt, SSH server)
├── devcontainer-base                     (this repository: + go, node, deno, prettier)
│   ├── devcontainer-classroom-web            (classroom image for web development)
│   ├── devcontainer-classroom-web-advanced   (+ playwright-deps; advanced web development, with AI)
│   └── devcontainer-dev                      (+ github-cli; development image)
└── devcontainer-classroom-exam-ts        (+ deno; standalone exam image)
```

All images use the shared release workflow and the layer tool `devcon` of
devcontainer-core. There are no Dev Container features.

## What the image contains

The image is the core image plus five layers. Each layer is one line in
[`.devcontainer/Dockerfile`](.devcontainer/Dockerfile):

| Layer      | Content                                                         | Version                     |
| ---------- | --------------------------------------------------------------- | --------------------------- |
| (core)     | Debian 13, user `dev` with zsh and sudo, locales, git settings, aliases, Pure prompt, SSH server on port 2222 | see devcontainer-core |
| `go`       | Go, gopls, dlv, staticcheck, govulncheck, golangci-lint         | Go: newest **1.27.x** (`GO_PIN=1.27`); gopls, dlv, staticcheck, govulncheck: newest release that works with this Go; golangci-lint: newest release |
| `build-tools` | make, gcc, g++, python3 for native npm modules (needed by `node`) | Debian packages          |
| `node`     | nvm, Node.js, npm (no pnpm, no yarn)                             | Node.js: newest **24.x** (`NODE_PIN=24`) |
| `deno`     | Deno                                                             | newest **2.x** (`DENO_PIN=2`) |
| `prettier` | Prettier with `prettier-plugin-tailwindcss`, global configuration `/.prettierrc.json` | newest release |

**Pinned release lines.** Go, Node.js and Deno are pinned with `ARG <TOOL>_PIN`
in the Dockerfile. The image gets every new release inside the pinned line.
When a pinned line reaches its end of life, the nightly check and the build
fail with a message that names the supported lines; then change the pin in the
Dockerfile. The rules are in
[Pinned release lines](https://github.com/majikmate/devcontainer-features#pinned-release-lines).

The details of every layer (build arguments, VS Code settings, tests) are in the
[layer list](https://github.com/majikmate/devcontainer-core/blob/main/docs/layers.md).
The exact versions of each release are listed in its
[release notes](https://github.com/majikmate/devcontainer-base/releases).

## Formatting

The image uses **Prettier** as the only formatter, with the **standard Prettier
style** (no style options).

- Prettier is the default formatter for all file types
  (`editor.defaultFormatter`), with format on save. Because of this, VS Code
  never uses the Deno formatter. If Prettier cannot format a file type, VS Code
  shows a short notice and does not format the file.
- Exception with its own standard formatter: Go (`gofmt` through the Go
  extension).
- PlantUML files are not formatted on save: the formatter of the PlantUML
  extension is deprecated, and Prettier cannot format PlantUML.
- The editor inserts 2 spaces per indentation level, the same as the standard
  Prettier output (Go uses tabs).
- **Tailwind CSS classes are sorted** into the standard order (in `class`,
  `className` and `@apply`). The layer `prettier` writes the global
  configuration `/.prettierrc.json`, which only loads the plugin
  `prettier-plugin-tailwindcss`. Prettier searches for a configuration from the
  folder of a file upward to `/`, so every project without its own Prettier
  configuration uses it — in the editor and with the `prettier` command in the
  terminal. A project with its own Prettier configuration uses its own
  configuration.
- The editor and the terminal use the same Prettier installation
  (`/usr/local/lib/node_modules/prettier`).

Deno stays the JavaScript/TypeScript runtime and language server
(`deno.enable: true`). The command `deno fmt` is part of Deno and still
exists, but the setup does not use it.

## VS Code configuration

The settings come from three places. The release workflow merges them into the
image label `devcontainer.metadata`:

| Source                                       | Settings                                                                                                  |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| devcontainer-core                            | user `dev`, terminal zsh, Markdown preview, theme "Dark (Visual Studio)", git (auto fetch, auto stash, rebase on sync, sync after commit), SSH start |
| layers `go`, `deno`, `prettier`              | extensions Go, Deno, Prettier; Go formatting with `gofmt`; Deno tests with `--allow-all --check=all`; debugger options `capAdd: SYS_PTRACE` and `init: true` |
| [`devcontainer.json`](.devcontainer/devcontainer.json) of this image | Prettier as default formatter, format on save, 2 spaces; PlantUML extension and server settings (no formatting of PlantUML files) |

## SSH access

The SSH server of devcontainer-core listens on port 2222 and accepts only the
public keys of your GitHub account (no password, no root login). See
[SSH access](https://github.com/majikmate/devcontainer-core#ssh-access):

- Codespaces: works without setup.
- Dev Containers extension: run `git config --global github.user <your-github-user>` once on your computer.
- `docker run` locally or on a VM: `docker run -d -p 2222:2222 -e GITHUB_USER=<your-github-user> ghcr.io/majikmate/devcontainer-base:2`, then `ssh -p 2222 dev@<host>`.

## Tags and versions

- `2.x.y` — Debian 13 "trixie" (current).
- `1.x.y` — Debian 12 "bookworm" (no more updates).
- `2`, `2.x` and `latest` always point to the newest `2.x.y` release.

Images that extend this base should use the major version tag (`:2`). They then
receive all compatible updates automatically, but no breaking changes.

## Automatic releases

The workflow [`.github/workflows/release.yml`](.github/workflows/release.yml)
uses the shared workflow of devcontainer-core. The rules (inputs, version steps,
tags, release notes) are described in
[Releases](https://github.com/majikmate/devcontainer-core#releases). In short:

- **Inputs:** the `.devcontainer` folder, the digest of
  `ghcr.io/majikmate/devcontainer-core:1`, and the newest versions of the tools
  of the layers `go`, `node`, `deno` and `prettier` (inside the pinned lines). They are stored in the
  image label `devcon.inputs`.
- **Nightly check at 01:17 UTC**, two hours after devcontainer-core (23:17 UTC).
  A new core image or a new tool version leads to a new release. The same
  happens when the newest image is older than 7 days (Debian updates).
- **Pull requests** build and test both architectures and publish nothing.
- **Version step:** patch; minor when Go 1.x changes or the major version of
  Node.js or Deno changes.

**Schedule of all images** (UTC). Each level runs two hours after the level it
builds on, so a change reaches all images within one night:

| Image                                                                                                   | Builds on | Nightly check |
| ------------------------------------------------------------------------------------------------------- | --------- | ------------- |
| [devcontainer-core](https://github.com/majikmate/devcontainer-core)                                     | Debian    | 23:17         |
| devcontainer-base (this repository)                                                                     | core      | 01:17         |
| [devcontainer-classroom-exam-ts](https://github.com/majikmate/devcontainer-classroom-exam-ts)           | core      | 01:27         |
| [devcontainer-dev](https://github.com/majikmate/devcontainer-dev)                                       | base      | 03:37         |
| [devcontainer-classroom-web](https://github.com/majikmate/devcontainer-classroom-web)                   | base      | 03:47         |
| [devcontainer-classroom-web-advanced](https://github.com/majikmate/devcontainer-classroom-web-advanced) | base      | 03:57         |

### Manual check and chain build

Open **Actions → Release → Run workflow**. With the option `upstream` (on by
default), the run first starts the Release workflow of devcontainer-core and
waits for it. Core releases a new version only if its own inputs changed. Then
this image runs its check; a new core image is a changed input.

The images that build on this base do the same: a manual run of
devcontainer-classroom-web starts this base, and this base starts core. Every
image in the chain runs its complete automatic check. `force` and `bump` apply
only to the image that you started. The chain build uses the GitHub App
`majikmate-devcontainer`; see
[Schedule and chain build](https://github.com/majikmate/devcontainer-core#schedule-and-chain-build).

## Extending the base

A new image builds on this base in its own `.devcontainer/Dockerfile` and adds
layers:

```dockerfile
FROM ghcr.io/majikmate/devcontainer-base:2

# github-cli: GitHub CLI
ARG GITHUB_CLI_VERSION
RUN devcon install github-cli
```

Its `.devcontainer/devcontainer.json` holds only its own VS Code settings; use
`"-publisher.extension"` to remove an extension of the base. See
[Writing an image](https://github.com/majikmate/devcontainer-core#writing-an-image).

## Development

```bash
# Build the image locally and run the layer tests
docker buildx build --load -t devcontainer-base:dev .devcontainer
docker run --rm --user dev --entrypoint devcon devcontainer-base:dev test
```

Change the image through a pull request: the pull request build tests both
architectures. After the merge, the image is released automatically.

## Related repositories

- [devcontainer-core](https://github.com/majikmate/devcontainer-core): the core
  image, the layer tool `devcon` and the shared release workflow
- [devcontainer-classroom-web](https://github.com/majikmate/devcontainer-classroom-web):
  classroom image for web development
- [devcontainer-classroom-web-advanced](https://github.com/majikmate/devcontainer-classroom-web-advanced):
  classroom image for advanced web development, with AI assistance
- [devcontainer-dev](https://github.com/majikmate/devcontainer-dev):
  development image
- [devcontainer-classroom-exam-ts](https://github.com/majikmate/devcontainer-classroom-exam-ts):
  standalone exam image for TypeScript/Deno

The concept of this structure: [docs/concept-docker-only.md](docs/concept-docker-only.md).

## License

MIT
