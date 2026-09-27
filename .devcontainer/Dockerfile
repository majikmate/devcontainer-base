# devcontainer-base: core + Go, Node.js, Deno and Prettier.
#
# The layer tool devcon of devcontainer-core installs every layer; one RUN line
# per layer. The release workflow passes the newest tool versions as build
# arguments; without them, each layer installs the newest version.
# Layers and their arguments: https://github.com/majikmate/devcontainer-core/blob/main/docs/layers.md
FROM ghcr.io/majikmate/devcontainer-core:1

# go: Go, gopls, dlv, staticcheck, govulncheck, golangci-lint
ENV GOROOT=/usr/local/go \
    GOPATH=/go \
    PATH=/go/bin:/usr/local/go/bin:$PATH
ARG GO_VERSION
ARG GOPLS_VERSION
ARG DLV_VERSION
ARG STATICCHECK_VERSION
ARG GOVULNCHECK_VERSION
ARG GOLANGCI_LINT_VERSION
RUN devcon install go

# build-tools: make, gcc, g++, python3 for native npm modules (node-gyp);
# the layer node needs it
RUN devcon install build-tools

# node: nvm, Node.js LTS, npm
ENV NVM_DIR=/usr/local/share/nvm \
    NVM_SYMLINK_CURRENT=true \
    PATH=/usr/local/share/nvm/current/bin:$PATH
ARG NVM_VERSION
ARG NODE_VERSION
RUN devcon install node

# deno: Deno LTS
ARG DENO_VERSION
RUN devcon install deno

# prettier: Prettier with the Tailwind CSS plugin (global configuration /.prettierrc.json)
ARG PRETTIER_VERSION
ARG PRETTIER_PLUGIN_TAILWINDCSS_VERSION
RUN devcon install prettier
