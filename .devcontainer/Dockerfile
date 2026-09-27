# devcontainer-base: core + Go, Node.js, Deno and Prettier.
#
# The layer tool devenv of devcontainer-core installs every layer; one RUN line
# per layer. The release workflow passes the newest tool versions as build
# arguments; without them, each layer installs the newest version.
#
# Pins (<TOOL>_PIN): the layer installs the newest release inside the pinned
# line. When the line reaches its end of life, the build fails and names the
# supported lines; then change the pin here.
# Layers and their arguments: https://github.com/majikmate/devcontainer-core/blob/main/docs/layers.md
FROM ghcr.io/majikmate/devcontainer-core:1

# go: Go 1.27.x; gopls, dlv, staticcheck, govulncheck in the newest version
# that works with it; golangci-lint
ENV GOROOT=/usr/local/go \
    GOPATH=/go \
    PATH=/go/bin:/usr/local/go/bin:$PATH
ARG GO_PIN=1.27
ARG GO_VERSION
ARG GOPLS_VERSION
ARG DLV_VERSION
ARG STATICCHECK_VERSION
ARG GOVULNCHECK_VERSION
ARG GOLANGCI_LINT_VERSION
RUN devenv install go

# build-tools: make, gcc, g++, python3 for native npm modules (node-gyp);
# the layer node needs it
RUN devenv install build-tools

# node: nvm, Node.js 24.x, npm
ENV NVM_DIR=/usr/local/share/nvm \
    NVM_SYMLINK_CURRENT=true \
    PATH=/usr/local/share/nvm/current/bin:$PATH
ARG NODE_PIN=24
ARG NVM_VERSION
ARG NODE_VERSION
RUN devenv install node

# deno: Deno 2.x
ARG DENO_PIN=2
ARG DENO_VERSION
RUN devenv install deno

# prettier: Prettier with the Tailwind CSS plugin (global configuration /.prettierrc.json)
ARG PRETTIER_VERSION
ARG PRETTIER_PLUGIN_TAILWINDCSS_VERSION
RUN devenv install prettier
