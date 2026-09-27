# Concept: images without Dev Container features

Status: **implemented** in
[devcontainer-core](https://github.com/majikmate/devcontainer-core). This
document is the record of the decisions. The current documentation is the
[README of devcontainer-core](https://github.com/majikmate/devcontainer-core#readme)
and its [layer list](https://github.com/majikmate/devcontainer-core/blob/main/docs/layers.md).

Differences between this concept and the implementation:

| Topic                       | Concept                                                                         | Implementation                                                                                                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Layer code                  | Bash scripts `install.sh` and `test.sh` per layer                               | One Go program `devcon` (static, `CGO_ENABLED=0`); each layer is one Go file. No Bash or Python scripts.                                                                                 |
| Dockerfile line of a layer  | `RUN $LAYERS/<layer>/install.sh`                                                | `RUN devcon install <layer>`                                                                                                                                                            |
| VS Code settings of a layer | In the `devcontainer.json` of each image                                        | Each layer declares its own settings (for example `capAdd` and `init` of the layer `go`); the release tool writes them into the label. `devcontainer.json` keeps the image's own settings. |
| Release tooling             | Shared workflow with shell steps, `tool-versions.sh`, `skopeo`                  | Shared workflow in devcontainer-core with the Go program `devcon-release`; own registry client. Only GitHub and Docker actions.                                                         |
| Chain build                 | From an image to its base image                                                  | Recursive: classroom-web starts base, base starts core.                                                                                                                                 |
| SSH keys                    | Keys of the owner's GitHub account (`GITHUB_USER`)                              | As planned, plus the git setting `github.user` for the Dev Containers extension and `docker run -e GITHUB_USER=…` for local Docker and VMs.                                           |

## 1. Goal

Today the images are built from Dev Container features: five features of the
`devcontainers` project (`common-utils`, `sshd`, `go`, `node`, `github-cli`)
and eight of the nine majikmate features. A new release of a third-party feature changes our
images without a change on our side. For example, `common-utils` 2.7.0 caused
release 2.0.1 of all images.

The goal:

1. **No features.** Every image installs everything itself in its Dockerfile.
2. **Full control.** Every installation step is our own code, and every
   download is checked against a checksum.
3. **Maintainable Dockerfiles.** Each former feature becomes one clearly
   separated _layer_ with its own script, test and description. The Dockerfile
   shows the composition of an image as a short list of layers.
4. **VS Code configuration stays in `devcontainer.json`.** Extensions and
   settings are not moved into the Dockerfile.
5. **Exact versions.** Each image contains exactly the tool versions that the
   release check found, and records them.

## 2. Decisions

| Topic                 | Decision                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Features              | None. All installation happens in the Dockerfiles.                                                                                               |
| VS Code configuration | Stays in `devcontainer.json` (extensions, settings, `remoteUser`, `capAdd`, `init`).                                                             |
| Shared parts          | A new image **devcontainer-core** contains the parts that devcontainer-base and devcontainer-classroom-exam-ts share.                            |
| Node.js               | **nvm stays.** nvm installs the newest Node.js LTS release and sets it as default. pnpm is installed. yarn is not installed.                     |
| Go tools              | `gopls`, `dlv`, `staticcheck`, `govulncheck` and `golangci-lint`. The other tools of the Go feature are not installed.                           |
| SSH server            | Stays in the images. Login with keys only: no password login (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`) and no root login. |
| Environment variables | Set with `ENV` in the Dockerfile (for example `PATH`, `GOPATH`, `NVM_DIR`), not with `containerEnv` in `devcontainer.json`.                      |
| Debugger options      | `capAdd: ["SYS_PTRACE"]` and `init: true` in `devcontainer.json` (see section 7).                                                                |

## 3. Open decisions

| Topic                                 | Options                                                                                                                                                                                                          | Recommendation                          |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| SSH keys                              | (a) keys of the container owner's GitHub account at container start; (b) no keys, only `gh codespace ssh`; (c) keys from a secret, written into the image at build time; (d) SSH server only in devcontainer-dev | (a), see section 8                      |
| Build tool                            | (a) `docker buildx` directly, the workflow writes the `devcontainer.metadata` label itself; (b) keep the Dev Container CLI (`devcontainers/ci`)                                                                  | (a), see section 9                      |
| Operating system update in containers | Today the feature `update-os` runs `apt-get upgrade` in every new container (`onCreateCommand`). (a) drop it; (b) keep it                                                                                        | (a): the nightly build already upgrades |
| devcontainer-features repository      | (a) archive it after the migration; (b) keep the features for other users                                                                                                                                        | (a)                                     |

## 4. Image structure

```
buildpack-deps:trixie-curl  (Debian 13, from Docker Hub)
        │
        └──► devcontainer-core                     NEW: user, shell, locale, git, prompt, SSH server
                    │
                    ├──► devcontainer-base         Go, Node.js (nvm), Deno, Prettier
                    │         ├──► devcontainer-classroom-web
                    │         ├──► devcontainer-classroom-web-advanced   + Playwright libraries
                    │         └──► devcontainer-dev                      + GitHub CLI
                    │
                    └──► devcontainer-classroom-exam-ts                  + Deno
```

- **devcontainer-core** is a new repository and image
  (`ghcr.io/majikmate/devcontainer-core:1`). It contains everything that every
  image needs, and the _layer library_ (section 5.3).
- devcontainer-base and devcontainer-classroom-exam-ts change their `FROM` line
  to `devcontainer-core`. Both keep their major version 2. The change is
  internal, so a new major version is not needed, unless the comparison in
  section 10 finds a difference that users notice.
- The chain build works as today: `upstream-repositories` of base and exam-ts
  becomes `devcontainer-core`, and `upstream-repositories` of the other three
  images stays `devcontainer-base`. A manual run of classroom-web then updates
  core, base and classroom-web in this order.

## 5. Layers

### 5.1 What a layer is

A layer replaces one feature. It is a folder with three files:

```
layers/<name>/
  install.sh    installs the layer (runs as root at build time)
  test.sh       checks the layer inside the built image (runs in the smoke test)
  README.md     what the layer installs, its build arguments and its sources
```

Rules for every layer:

- `install.sh` starts with `set -euo pipefail`, reads its settings only from
  build arguments (environment variables), and prints what it installs.
- Every download is checked: a SHA-256 checksum from the publisher, or a signed
  package source (for example the GitHub CLI package source).
- A layer supports `amd64` and `arm64`. It reads the architecture with
  `dpkg --print-architecture`.
- A layer removes its temporary files and the apt package lists
  (`/var/lib/apt/lists/*`) at the end, so that the Docker layer stays small.
- A layer never changes files of another layer. The order of the layers in the
  Dockerfile is the only dependency (for example `prettier` after `node`).

### 5.2 Layer inventory

| Layer             | Replaces feature            | Image         | Content                                                                                                                                               | Version from       |
| ----------------- | --------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `os`              | `update-os` (build part)    | core          | `apt-get upgrade`, base packages (curl, ca-certificates, git, less, procps, jq, sudo, zsh, locales, openssh-server, …)                                | Debian             |
| `user`            | `common-utils`              | core          | user `dev` (UID/GID 1000), sudo without password, zsh as default shell                                                                                | –                  |
| `locales`         | majikmate `locales`         | core          | `en_US.UTF-8`, time zone                                                                                                                              | –                  |
| `git`             | majikmate `git`             | core          | system git configuration (rebase on pull, auto stash)                                                                                                 | Debian             |
| `aliases`         | majikmate `aliases`         | core          | shell aliases (`ls`, `ll`, `vs`, `grep`)                                                                                                              | –                  |
| `pure-prompt`     | majikmate `pure-prompt`     | core          | Pure prompt for zsh                                                                                                                                   | Git tag            |
| `sshd`            | `sshd`                      | core          | OpenSSH server on port 2222, keys only, no root login; start script (section 8)                                                                       | Debian             |
| `go`              | `go`                        | base          | Go in `/usr/local/go`, `GOPATH=/go` (writable for user `dev`); `gopls`, `dlv`, `staticcheck`, `govulncheck`; `golangci-lint` from its release archive | `tool-versions.sh` |
| `node`            | `node`                      | base          | nvm in `/usr/local/share/nvm` (writable for user `dev`), newest Node.js LTS as default, pnpm, node-gyp build dependencies                             | `tool-versions.sh` |
| `deno`            | majikmate `deno`            | base, exam-ts | Deno LTS in `/usr/local/bin`                                                                                                                          | `tool-versions.sh` |
| `prettier`        | majikmate `prettier`        | base          | Prettier and `prettier-plugin-tailwindcss` in `/usr/local`, global configuration `/.prettierrc.json`                                                  | `tool-versions.sh` |
| `playwright-deps` | majikmate `playwright-deps` | web-advanced  | system libraries for the Playwright browsers                                                                                                          | Debian             |
| `github-cli`      | `github-cli`                | dev           | GitHub CLI from its signed Debian package source                                                                                                      | `tool-versions.sh` |

The VS Code parts of the features move into `devcontainer.json`:

| From feature                                                  | Into `devcontainer.json` of        |
| ------------------------------------------------------------- | ---------------------------------- |
| `go`: `golang.go`, `capAdd`, `init`                           | base                               |
| `deno`: `denoland.vscode-deno`                                | base, exam-ts                      |
| `prettier`: `esbenp.prettier-vscode`, `prettier.prettierPath` | base                               |
| `node`: `dbaeumer.vscode-eslint`                              | not needed (base removes it today) |

### 5.3 The layer library in the core image

All layer scripts live in the devcontainer-core repository and are copied into
the core image at `/usr/local/share/majikmate/layers/`. Every image that is
built on core can therefore use every layer with one `RUN` line, without a copy
of the script.

- One source: a layer exists only once.
- A layer and the images that use it change in a known order: a new layer
  version is released with core, and the chain build brings it into the other
  images.
- The scripts are small text files, so the core image grows by only a few
  kilobytes.

Images that are not built on core (none today) would copy the scripts from the
core repository instead.

### 5.4 Dockerfile composition

Each Dockerfile is a short list of layers. Each layer is one `RUN` step and
therefore one Docker layer, so `docker history` shows the same structure as the
Dockerfile. The OCI metadata stays at the end of each Dockerfile, as today.

devcontainer-core:

```dockerfile
FROM buildpack-deps:trixie-curl

COPY layers/ /usr/local/share/majikmate/layers/
ENV LAYERS=/usr/local/share/majikmate/layers

# ── os ──────────────────────────────────────────────────────────────────────
RUN $LAYERS/os/install.sh

# ── user ────────────────────────────────────────────────────────────────────
ARG USERNAME=dev USER_UID=1000 USER_GID=1000
RUN $LAYERS/user/install.sh

# ── locales ─────────────────────────────────────────────────────────────────
ARG LANG_DEFAULT=en_US.UTF-8
ENV LANG=${LANG_DEFAULT} LC_ALL=${LANG_DEFAULT}
RUN $LAYERS/locales/install.sh

# ── git, aliases, pure-prompt ───────────────────────────────────────────────
RUN $LAYERS/git/install.sh
RUN $LAYERS/aliases/install.sh
ARG PURE_VERSION
RUN $LAYERS/pure-prompt/install.sh

# ── sshd ────────────────────────────────────────────────────────────────────
RUN $LAYERS/sshd/install.sh

USER dev
# … OCI labels as today
```

devcontainer-base:

```dockerfile
FROM ghcr.io/majikmate/devcontainer-core:1
USER root

# ── go ──────────────────────────────────────────────────────────────────────
ARG GO_VERSION GOLANGCI_LINT_VERSION GOPLS_VERSION DLV_VERSION STATICCHECK_VERSION GOVULNCHECK_VERSION
ENV GOROOT=/usr/local/go GOPATH=/go
ENV PATH=/usr/local/go/bin:/go/bin:$PATH
RUN $LAYERS/go/install.sh

# ── node ────────────────────────────────────────────────────────────────────
ARG NVM_VERSION NODE_VERSION PNPM_VERSION
ENV NVM_DIR=/usr/local/share/nvm
ENV PATH=/usr/local/share/nvm/current/bin:$PATH
RUN $LAYERS/node/install.sh

# ── deno ────────────────────────────────────────────────────────────────────
ARG DENO_VERSION
RUN $LAYERS/deno/install.sh

# ── prettier ────────────────────────────────────────────────────────────────
ARG PRETTIER_VERSION PRETTIER_TAILWIND_VERSION
RUN $LAYERS/prettier/install.sh

USER dev
# … OCI labels as today
```

devcontainer-classroom-web needs no layer: its Dockerfile is only `FROM` and the
OCI labels. devcontainer-dev adds `github-cli`, devcontainer-classroom-web-advanced
adds `playwright-deps`, and devcontainer-classroom-exam-ts adds `deno`.

## 6. Versions

Today a feature resolves `latest` or `lts` itself during the build, and
`.github/tool-versions.sh` only watches the versions.

New: `tool-versions.sh` finds the versions once, and the workflow passes them
as build arguments (`--build-arg GO_VERSION=1.27.1`, …). The layers install
exactly these versions and never resolve `latest` themselves.

- The image contains exactly the versions that the release check found.
- The build arguments are the "tool" inputs of the fingerprint, as today.
- A local build without build arguments fails with a clear message, or uses a
  default version written in the Dockerfile. This is decided during the
  implementation.
- New sources in `tool-versions.sh`: the Go tools, read from the Go module
  proxy (`https://proxy.golang.org/<module>/@latest`), and the Pure prompt
  version (Git tags).

## 7. `devcontainer.json` and the `devcontainer.metadata` label

`devcontainer.json` stays the only place for the configuration of VS Code and of
the container start:

- `customizations.vscode.extensions` and `customizations.vscode.settings`;
- `remoteUser`;
- `capAdd: ["SYS_PTRACE"]` and `init: true`. These are options for starting the
  container, not content of the image, so a Dockerfile cannot set them. VS Code
  and Codespaces read them from the image label;
- `postStartCommand` and `entrypoint` of the SSH server (section 8).

Every image carries this configuration in the label `devcontainer.metadata`.
The label is a JSON list with one entry per level: core, then base, then the
image itself. VS Code, Codespaces and the Dev Container CLI read it from the
image. Therefore an assignment repository that uses only
`"image": "ghcr.io/majikmate/devcontainer-classroom-web:2"` receives all
settings of all levels.

Environment variables are set with `ENV` in the Dockerfile. Then every tool
works in every context, including `docker run` without Dev Container tools (for
example in the smoke test).

## 8. SSH server

**Server (layer `sshd`, core image):**

- OpenSSH server, port 2222. The port is not forwarded by default.
- `PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
  `PermitRootLogin no`, `AuthorizedKeysFile .ssh/authorized_keys`.
- Host keys are created at the first start of a container, not at build time.
  Otherwise all containers of an image would share the same host keys.
- The server is started as root by the `entrypoint` entry of the label, as the
  `sshd` feature does today.

**Keys (open decision, recommendation (a)):** at every container start, a script
reads the public keys of the container owner from GitHub and writes them to
`/home/dev/.ssh/authorized_keys`.

- Owner: in Codespaces, the variable `GITHUB_USER` contains the owner of the
  codespace. Locally, the user can set `GITHUB_USER` in their own
  `devcontainer.json`
  (`"containerEnv": { "GITHUB_USER": "${localEnv:GITHUB_USER}" }`).
- Source: `https://github.com/<user>.keys` (public, no token needed).
- The script replaces the file. A key that the owner deletes on GitHub stops
  working at the next start.
- If `GITHUB_USER` is not set or GitHub cannot be reached, the script keeps the
  previous keys and the container starts normally.
- The script runs as `postStartCommand` of the label, as user `dev`.
- **To check before the implementation:** that `GITHUB_USER` is set for
  `postStartCommand` in Codespaces, not only in terminals.

Sketch of the script:

```bash
#!/usr/bin/env bash
# Adds the SSH keys of the container owner (GitHub account in GITHUB_USER)
[ -n "${GITHUB_USER:-}" ] || exit 0
keys="$(curl -fsSL --max-time 10 "https://github.com/${GITHUB_USER}.keys")" || exit 0
[ -n "$keys" ] || exit 0
install -d -m 700 ~/.ssh
printf '%s\n' "$keys" > ~/.ssh/authorized_keys.new
chmod 600 ~/.ssh/authorized_keys.new
mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys
```

**Why not keys from a secret (option (c)):**

1. Every key holder could log in to every container of the public images whose
   SSH port is reachable, including student containers, without the students
   knowing it.
2. Public keys are not secret. An access list belongs in a visible, reviewed
   place, not in a hidden secret.
3. Removing a key needs a rebuild of all images and a new pull by every user.
4. `gh codespace ssh` does not need built-in keys: it adds its own temporary
   key.

**Connection:** in Codespaces with `gh codespace ssh`, or with `ssh` after
`gh codespace ports forward 2222:2222`. Locally, the user forwards port 2222 in
their own `devcontainer.json` and connects with `ssh -p 2222 dev@localhost`.

## 9. Build and release workflow

The shared workflow `devcontainer-image.yml` keeps its logic (inputs, nightly
check, chain build, versions, tags, GitHub release). These parts change:

| Part          | Today                                                            | New                                                                                                                                                        |
| ------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Inputs        | configuration, base image digest, feature digests, tool versions | configuration, base image digest, tool versions (no features)                                                                                              |
| Build         | `devcontainers/ci` (Dev Container CLI)                           | open decision: `docker buildx build` with `--build-arg` for the versions (recommended), or the CLI                                                         |
| Label         | written by the CLI                                               | with `docker buildx`: the workflow reads the label of the `FROM` image, adds the entry from `devcontainer.json` and sets `--label devcontainer.metadata=…` |
| Smoke test    | `runCmd` inside the container started by the CLI                 | `docker run --user dev <image>`: the `test.sh` of every layer of the image, then the image-specific checks                                                 |
| Version check | compares the smoke test output with `tool-versions.sh`           | the same, but a difference now fails the build, because the layers install exact versions                                                                  |

With `docker buildx`, the workflow needs no Dev Container tools, and SBOM and
provenance attestations are easy to add later.

## 10. Migration

1. Create the repository `majikmate/devcontainer-core` (by an organization
   owner). Add the release workflow and the layers `os`, `user`, `locales`,
   `git`, `aliases`, `pure-prompt`, `sshd`. Release `devcontainer-core` 1.0.0.
2. Add the layers `go`, `node`, `deno`, `prettier`, `playwright-deps` and
   `github-cli` to the core repository, and extend `tool-versions.sh`.
3. Change the shared workflow (section 9).
4. Change devcontainer-base to `FROM devcontainer-core:1` with its layers.
5. Change devcontainer-classroom-exam-ts to `FROM devcontainer-core:1`.
6. Change devcontainer-classroom-web, devcontainer-classroom-web-advanced and
   devcontainer-dev (remove their features).
7. **Comparison:** for every image and both architectures, compare the old and
   the new image: installed packages, tool versions, environment variables,
   user and groups, default shell, locale, git configuration, prompt, SSH
   configuration and the `devcontainer.metadata` label. Every difference must be
   intended.
8. Update all READMEs. Archive `devcontainer-features` (open decision). Remove
   the `devcontainers` ecosystem from the Dependabot configurations; keep
   `docker` and `github-actions`.

Each step is one pull request. The images keep working after every merged step,
because each image changes only when its own pull request is merged.

## 11. Effort

| Work                                                                     | Days      |
| ------------------------------------------------------------------------ | --------- |
| devcontainer-core: repository, core layers, release                      | 1         |
| Layers `go`, `node`, `deno`, `prettier`, `playwright-deps`, `github-cli` | 1         |
| Shared workflow: build arguments, own label, new smoke test              | 1         |
| Change the five images                                                   | 0.5       |
| Comparison of old and new images                                         | 0.5–1     |
| Documentation, Dependabot, archiving                                     | 0.5       |
| **Total**                                                                | **4.5–5** |

After the migration, we maintain the installation of Go, Node.js, Deno, the Go
tools, golangci-lint and the GitHub CLI ourselves. Their download formats
rarely change. The expected effort is a few hours per year.

## 12. Risks

| Risk                                                                                 | Measure                                                                                             |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| A difference to the current images that users notice (for example a missing package) | the comparison in step 7 of section 10, before the images are released                              |
| A download format of a tool changes                                                  | the nightly build fails and publishes nothing; the previous image stays in use                      |
| A wrong `devcontainer.metadata` label: students lose their VS Code settings          | the smoke test checks the label (valid JSON, expected extensions and settings)                      |
| `GITHUB_USER` is not available for `postStartCommand`                                | checked before the implementation (section 8); otherwise the script runs from the shell start files |
