# DevContainer Base

The base [Dev Container](https://containers.dev/) image for the majikmate
classroom and development environments. It contains Go, Node.js, Deno, Prettier
and common tools on Debian 13 "trixie", and a shared VS Code configuration.

Published image: `ghcr.io/majikmate/devcontainer-base` (linux/amd64 and
linux/arm64)

## Images and their dependencies

```
devcontainer-features  (features: locales, aliases, git, pure-prompt, deno, prettier, playwright-deps, update-os)
        │
        ├──► devcontainer-base      (this repository)
        │           ├──► devcontainer-classroom-web            (classroom image for web development)
        │           ├──► devcontainer-classroom-web-advanced   (advanced web development, with AI)
        │           └──► devcontainer-dev                      (development image)
        │
        └──► devcontainer-classroom-exam-ts                   (standalone exam image, Deno only)
```

All these images use the shared release workflow of this repository (see
[Automatic releases](#automatic-releases)).

## What the image contains

| Tool                                                                  | Version                                    | Installed by                                           |
| --------------------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------------ |
| Debian                                                                | 13 "trixie" (`buildpack-deps:trixie-curl`) | `.devcontainer/Dockerfile`                             |
| Go, golangci-lint                                                     | newest release (no beta/rc)                | `ghcr.io/devcontainers/features/go:1`                  |
| Node.js, npm                                                          | newest **LTS** release                     | `ghcr.io/devcontainers/features/node:2`                |
| pnpm, nvm                                                             | newest release                             | `ghcr.io/devcontainers/features/node:2`                |
| Deno                                                                  | newest **LTS** release                     | `ghcr.io/majikmate/devcontainer-features/deno:1`       |
| Prettier, Tailwind CSS plugin                                         | newest release                             | `ghcr.io/majikmate/devcontainer-features/prettier:1`   |
| zsh with Pure prompt, SSH server, locales, aliases, git configuration | –                                          | `common-utils:2`, `sshd:1`, and the majikmate features |

Operating system packages are upgraded at build time (feature `update-os`). The
default user is `dev` (UID/GID 1000).

The exact versions of each release are listed in its
[release notes](https://github.com/majikmate/devcontainer-base/releases).

## Formatting

The image uses **Prettier** as the only formatter, with the **standard Prettier
style** (no style options).

- Prettier is the default formatter for all file types
  (`editor.defaultFormatter`), with format on save. Because of this, VS Code
  never uses the Deno formatter. If Prettier cannot format a file type, VS Code
  shows a short notice and does not format the file.
- Exceptions with their own standard formatter: Go (`gofmt` through the Go
  extension) and PlantUML.
- The editor inserts 2 spaces per indentation level, the same as the standard
  Prettier output (Go uses tabs).
- **Tailwind CSS classes are sorted** into the standard order (in `class`,
  `className` and `@apply`). The feature `prettier` writes the global
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

- Extensions: GitHub Markdown preview, Go, Deno, Prettier, PlantUML, PDF viewer.
  The ESLint extension that the Node.js feature adds is removed.
- Terminal: zsh.
- Markdown files open in the preview.
- Theme: "Dark (Visual Studio)".
- Deno test code lens and Test Explorer run tests with
  `--allow-all --check=all`.
- Git: auto fetch, auto stash, rebase on sync, sync after commit.
- PlantUML: rendering on the PlantUML server, export as SVG.

## Tags and versions

- `2.x.y` — Debian 13 "trixie" (current).
- `1.x.y` — Debian 12 "bookworm" (no more updates).
- `2`, `2.x` and `latest` always point to the newest `2.x.y` release.

Images that extend this base should use the major version tag (`:2`). They then
receive all compatible updates automatically, but no breaking changes.

## Automatic releases

Tools that are installed as "latest" or "lts" are fixed when an image is built.
To keep the image current, the workflow
[`.github/workflows/release.yml`](.github/workflows/release.yml) runs every
hour and builds a new image when one of its inputs changed. The logic is in the
shared workflow
[`.github/workflows/devcontainer-image.yml`](.github/workflows/devcontainer-image.yml),
which the other image repositories use as well.

**Inputs of the image**

1. The content of the `.devcontainer` folder.
2. The digest of the base image `buildpack-deps:trixie-curl`.
3. The digest of every feature. Features are pinned by major version, so a new
   minor or patch version of a feature changes this digest.
4. The newest versions of the tools, read by
   [`.github/tool-versions.sh`](.github/tool-versions.sh) from the same sources
   that the installers use: Go (Go git tags), Node.js LTS (Node.js release
   index), Deno LTS (`dl.deno.land`), pnpm, nvm, golangci-lint, Prettier and the
   Tailwind CSS plugin.

The inputs are stored in the image label `io.github.majikmate.devcontainer.inputs`.

**When a new version is released**

| Event                       | Result                                                                                               |
| --------------------------- | ---------------------------------------------------------------------------------------------------- |
| Pull request                | Build and test both architectures. Nothing is published.                                             |
| Push to `main`              | Release if an input changed.                                                                         |
| Hourly check                | Release if an input changed, or if the newest image is older than 7 days (operating system updates). |
| Tag `vX.Y.Z` pushed         | Release exactly this version.                                                                        |
| Manual run ("Run workflow") | Options `force` (release even without changes) and `bump`.                                           |

**Version numbers**: automatic releases increase the patch number. The minor
number increases when the major version of Go (1.x), Node.js or Deno changes.
The major version is set in `release.yml` (`major-version`); increase it
together with a breaking change.

**Every release**

- is built without build cache, so it contains the newest tools and packages;
- is tested inside the built container (versions, Debian release, Prettier with
  Tailwind CSS sorting, Deno);
- gets the tags `X.Y.Z`, `X.Y`, `X` and `latest`, and a GitHub release whose
  notes list the reason, the installed versions and all inputs.

The images that extend this base run the same hourly check. They find the new
base image digest and release themselves.

> GitHub turns off scheduled workflows in public repositories after 60 days
> without activity. The hourly run re-enables its own workflow to prevent this.
> If it is turned off anyway, enable it again under **Actions → Release**.

## Extending the base

```jsonc
{
  "name": "My Project",
  "image": "ghcr.io/majikmate/devcontainer-base:2",
  "features": {
    // Add additional features here
  },
  "customizations": {
    "vscode": {
      "extensions": [
        // Add project-specific extensions
        // Use "-publisher.extension" to remove an extension of the base
      ],
      "settings": {
        // Override or add settings
      },
    },
  },
}
```

The VS Code settings and extensions of the base are stored in the image and
apply to every image that extends it.

## Development

```bash
# Build and start the container locally
devcontainer build --workspace-folder .
devcontainer up --workspace-folder .

# Check the newest tool versions
.github/tool-versions.sh
```

Change the image through a pull request: the pull request build tests both
architectures. After the merge, the image is released automatically.

## Related repositories

- [devcontainer-features](https://github.com/majikmate/devcontainer-features):
  the majikmate features used by this image
- [devcontainer-classroom-web](https://github.com/majikmate/devcontainer-classroom-web):
  classroom image for web development
- [devcontainer-classroom-web-advanced](https://github.com/majikmate/devcontainer-classroom-web-advanced):
  classroom image for advanced web development, with AI assistance
- [devcontainer-dev](https://github.com/majikmate/devcontainer-dev):
  development image
- [devcontainer-classroom-exam-ts](https://github.com/majikmate/devcontainer-classroom-exam-ts):
  standalone exam image for TypeScript/Deno (uses the shared release workflow)

## License

MIT
