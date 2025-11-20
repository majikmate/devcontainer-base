# DevContainer Base

This repository contains a base devcontainer configuration that provides common
development tools and settings for Go, Node.js, and Deno development
environments. It serves as the foundation for specialized devcontainer projects.

## Overview

The base configuration consolidates common functionality that was previously
duplicated across multiple devcontainer projects. It includes:

- **Base Image**: Debian Bookworm (buildpack-deps)
- **Programming Languages**: Go (latest), Node.js (LTS), Deno (latest)
- **Development Tools**: Git configuration, common utilities, locales, aliases
- **VS Code Configuration**: Essential extensions and settings for development

## Architecture

This base configuration is extended by specialized environments:

```
devcontainer-base (this repo)
├── Base Dockerfile with OCI metadata
├── Core features (Go, Node.js, Deno, git, etc.)
├── Common VS Code settings
└── GitHub Actions workflow for publishing

devcontainer-dev
├── Extends: ghcr.io/majikmate/devcontainer-base:latest
├── Adds: GitHub CLI, devcontainer CLI
├── User: dev
└── Dev-specific extensions and JSON schemas

devcontainer-classroom-web
├── Extends: ghcr.io/majikmate/devcontainer-base:latest
├── Adds: LiveServer, Lorem Ipsum extensions
├── User: student
├── Disables: AI features, GitHub extensions
└── Hides: Configuration folders
```

## Features Included

### Core Development Features

- **common-utils** (v2.5.4): Basic development utilities with custom user
  management
- **go** (v1.3.2): Latest Go development environment
- **node** (v1.6.3): Node.js LTS with npm, pnpm, and nvm
- **deno** (v1.0.0): Latest Deno runtime
- **locales** (v1.0.2): US English locale configuration
- **aliases** (v1.0.1): Helpful command aliases (ls, ll, vs, grep)
- **git** (v1.0.0): Git configuration and optimizations
- **update-os** (v1.0.0): System updates (runs last in feature order)

### VS Code Configuration

- **Extensions**:
  - Markdown preview (`bierner.github-markdown-preview`)
  - Go language support (`golang.go`)
  - Deno runtime support (`denoland.vscode-deno`)
  - PlantUML diagrams (`jebbs.plantuml`)
  - PDF viewer (`tomoki1207.pdf`)
- **Settings**:
  - Terminal configuration (zsh default)
  - Editor settings with Deno formatter for web files
  - Git workflows with auto-sync
  - PlantUML local rendering with SVG export
- **Theme**: Visual Studio Dark
- **Deno Integration**: Enabled as TypeScript language server
- **Formatting**: Deno configured as default formatter for:
  - HTML, CSS
  - JavaScript, TypeScript, JSX, TSX
  - JSON, JSONC

### Git Workflow Optimization

The configuration includes optimized Git settings for smooth development
workflows:

- Auto-fetch and auto-stash enabled
- Rebase-based sync operations
- Smart commit behavior
- Automatic post-commit sync

## Usage

### Extending the Base

To use this base configuration in your project, reference the published image:

```json
{
    "name": "My Project",
    "image": "ghcr.io/majikmate/devcontainer-base:latest",
    "remoteUser": "dev",
    "features": {
        // Add additional features here
    },
    "customizations": {
        "vscode": {
            "extensions": [
                // Add project-specific extensions
            ],
            "settings": {
                // Override or add settings
            }
        }
    }
}
```

### Examples

See the `examples/` directory for complete working examples:

- **`dev-example/`**: Development environment with GitHub CLI and devcontainer
  CLI
- **`classroom-example/`**: Educational environment with student user and
  disabled AI features

## Container Registry

The base image is published to GitHub Container Registry:

- **Registry**: `ghcr.io/majikmate/devcontainer-base`
- **Tags**: `latest` (main branch), versioned tags for releases
- **Architectures**: AMD64, ARM64

## Customization Patterns

### User Configuration

The base uses `dev` as the default user. Override this in extending
configurations:

```json
{
    "remoteUser": "student",
    "features": {
        "ghcr.io/devcontainers/features/common-utils:2.5.4": {
            "username": "student",
            "userUid": "1000",
            "userGId": "1000"
        }
    }
}
```

### Adding Project-Specific Features

```json
{
    "features": {
        "ghcr.io/devcontainers/features/github-cli:1.0.15": {
            "installDirectlyFromGitHubRelease": true,
            "version": "latest"
        }
    }
}
```

### Disabling Extensions

Use negative extension names to disable unwanted extensions:

```json
{
    "customizations": {
        "vscode": {
            "extensions": [
                "-github.copilot",
                "-github.copilot-chat"
            ]
        }
    }
}
```

## Development

### Building Locally

```bash
# Build the container
devcontainer build .devcontainer

# Test the container
devcontainer up .devcontainer
```

### Publishing

The container is automatically built and published via GitHub Actions:

- **On push to main**: Builds and caches (doesn't publish)
- __On version tag (v_)_*: Builds, caches, and publishes to registry

## Migration from Standalone Configurations

If migrating from a standalone devcontainer configuration:

1. **Remove Dockerfile**: No longer needed, use base image instead
2. **Update devcontainer.json**: Change from `"build"` to `"image"` reference
3. **Remove duplicate features**: Common features are now in the base
4. **Keep only specific customizations**: Extensions, settings, and features
   unique to your use case
5. **Update workflows**: Remove OCI metadata build args, simplify build process

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes with extending configurations
4. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Related Repositories

- **devcontainer-dev**: Development environment extending this base
- **devcontainer-classroom-web**: Classroom environment extending this base
