# devcontainer-base

The base image of the classroom and development images: devcontainer-core plus
Go, Node.js, the command `ts`, Deno and Prettier, with a shared VS Code
configuration.

**Image:** `ghcr.io/majikmate/devcontainer-base:2` · linux/amd64, linux/arm64 ·
[release notes](https://github.com/majikmate/devcontainer-base/releases)

## Dependencies

```text
                                               Nightly Content
devcontainer-features                                  Go library of layers, compiled into devcon
  ▼
devcontainer-core:1                            22:17   Debian 13, devcon, user dev, zsh, SSH server
├── devcontainer-base:2                        23:17   + go, build-tools, node, ts, deno, prettier
│   ├── devcontainer-dev:2                     23:57   + github-cli
│   ├── devcontainer-classroom-web:2           00:07   + html-validate, classroom settings, AI off
│   └── devcontainer-classroom-web-advanced:2  00:17   + playwright-deps, html-validate, AI on
└── devcontainer-classroom-exam-ts:2           23:47   + build-tools, node, ts, deno, AI and coding assistance off
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
- A full version (for example `:2.0.8`) stays available until five newer
  releases exist; only the newest 5 releases are kept.
- See [Writing an image](https://github.com/majikmate/devcontainer-core#writing-an-image).

## Content

Each layer is one line in [`.devcontainer/Dockerfile`](.devcontainer/Dockerfile):

| Layer | Content | Version |
| ----- | ------- | ------- |
| (devcontainer-core) | Debian 13, user `dev`, zsh, locales, git settings, aliases, Pure prompt, SSH server on port 2222 | see [core](https://github.com/majikmate/devcontainer-core#content); Debian release: [`debianPin`](https://github.com/majikmate/devcontainer-core/blob/main/pkg/layers/os.go#L31-L34) |
| `go` | Go, gopls, dlv, staticcheck, govulncheck, golangci-lint | Go 1.27.x; the Go tools in the newest version that works with this Go ([`goPin`](https://github.com/majikmate/devcontainer-features/blob/main/golang/golang.go#L49-L54)) |
| `build-tools` | make, gcc, g++, python3 (for native npm modules) | Debian packages of the Debian release ([`debianPin`](https://github.com/majikmate/devcontainer-core/blob/main/pkg/layers/os.go#L31-L34)) |
| `node` | nvm, Node.js, npm (no pnpm, no yarn) | Node.js 26.x LTS, the newest LTS release of the line ([`nodePin`, `nodeChannel`](https://github.com/majikmate/devcontainer-features/blob/main/node/node.go#L40-L45)) |
| `ts` | the command `ts` of [`@nimblescape/typescript`](https://www.npmjs.com/package/@nimblescape/typescript) (checks, compiles and runs TypeScript with tsc and Node.js), Tab completion in zsh and bash, VS Code extension nimblescape TypeScript | newest release ([`tsPin`](https://github.com/majikmate/devcontainer-features/blob/main/ts/ts.go#L35-L38)) |
| `deno` | Deno | Deno 2.x LTS, the release of `deno upgrade lts` ([`denoPin`, `denoChannel`](https://github.com/majikmate/devcontainer-features/blob/main/deno/deno.go#L36-L39)) |
| `prettier` | Prettier with `prettier-plugin-tailwindcss`, global configuration `/.prettierrc.json` | newest release ([`prettierPin`](https://github.com/majikmate/devcontainer-features/blob/main/prettier/prettier.go#L32-L37)) |

**Versions:** the features decide the pinned lines and channels, not this
Dockerfile ([rules](https://github.com/majikmate/devcontainer-features#versions)).
When a pinned line reaches its end of life, the nightly check and the build
fail and name the supported lines.
Details of all layers:
[docs/layers.md](https://github.com/majikmate/devcontainer-core/blob/main/docs/layers.md).

## VS Code

- **Extensions:** Go, Deno, Prettier, Markdown preview,
  [nimblescape TypeScript](https://marketplace.visualstudio.com/items?itemName=nimblescape.nimblescape-typescript)
  (from the layers),
  [nimblescape PlantUML](https://marketplace.visualstudio.com/items?itemName=nimblescape.nimblescape-plantuml),
  [nimblescape Mindbug](https://marketplace.visualstudio.com/items?itemName=nimblescape.nimblescape-mindbug),
  [nimblescape Comment Links](https://marketplace.visualstudio.com/items?itemName=nimblescape.nimblescape-commentlinks)
  and the
  [PDF Viewer](https://marketplace.visualstudio.com/items?itemName=mathematic.vscode-pdf)
  (from [`devcontainer.json`](.devcontainer/devcontainer.json)).
- **PlantUML:** the diagrams in PlantUML files and in the `plantuml` blocks of
  Markdown files render in the editor itself, without a PlantUML server, Java
  or Graphviz.
- **Mindbug:** shows the stack and the heap of a TypeScript program as a
  diagram while it is debugged (command **Run with Mindbug**), with Deno or
  Node.js.
- **Comment Links:** a Markdown link in a code comment, for example
  `// Assures: [A-UNIT-001](docs/unit.md#a-unit-001)`, shows only its label.
  Ctrl+click (Cmd+click on macOS) on the label opens the target file at the
  heading that the link names. The line of the cursor shows the whole link,
  and the extension completes the paths and the headings while you write a
  link.
- **TypeScript:** `ts main.ts` checks `main.ts` with `tsc`, compiles it and
  runs it with Node.js, with the global functions `prompt()`, `alert()` and
  `confirm()`. In the terminals of VS Code, `ts` uses the TypeScript of VS
  Code; the image installs no TypeScript of its own. Tab completes the options
  of `ts` in zsh and bash. F5 runs a TypeScript file with the debug type `ts`,
  and in a folder without `tsconfig.json` the editor shows the same errors as
  `ts`. The completions of a TypeScript file offer no import of a name that is
  global already, such as `log` from `node:console` or `parseInt` from
  `es-toolkit/compat`.
- **Formatting:** Prettier formats all languages except Go and PlantUML, with
  the standard Prettier style, format on save and 2 spaces. Tailwind CSS
  classes are sorted. A project with its own Prettier configuration uses that
  configuration. Go uses `gofmt`; the PlantUML extension formats PlantUML
  files and the PlantUML blocks of Markdown files.
- **Deno** is installed as a JavaScript/TypeScript runtime, not the formatter.
  The Deno extension is off (`"deno.enable": false`, from the layer `deno`),
  because the courses run on Node.js. A project that runs on Deno turns it on
  in its own `devcontainer.json` (`"deno.enable": true`).
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
- **Kept versions:** the newest 5 releases and the tags `2`, `2.x` and
  `latest`. Older releases are deleted after every release run, and workflow
  runs after 30 days. **Actions → Prune** lists or deletes them at once; the
  scope `all-but-newest` keeps only the newest release and the newest run of
  each workflow.

Rules: [Releases](https://github.com/majikmate/devcontainer-core#releases).

## Change the image

Change `.devcontainer/` or `README.md` through a pull request. After the merge,
the new image is released automatically (GitHub shows the README of the newest
image on the package page).

---

© 2026 Hannes Stauss (scalarion@nimblescape.com) · [MIT License](LICENSE).
