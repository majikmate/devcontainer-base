#!/usr/bin/env bash
# Prints the newest upstream version of every tool that the image installs with
# "latest" or "lts", one line per tool: <name>=<version>
#
# The release workflow runs this script every hour. When a version differs from
# the version recorded in the current image, it rebuilds and releases the image.
# Each probe reads the same source as the installer of the tool. A probe that
# fails prints an empty value; the workflow then keeps the previous value.
set -uo pipefail

probe() {
    local name="$1"
    shift
    local value
    value="$("$@" 2>/dev/null | head -n 1 | tr -d '[:space:]')" || value=""
    echo "${name}=${value}"
}

# Go: newest final release (no beta/rc), from the Go git tags like the Go feature
go_latest() {
    git ls-remote --tags https://go.googlesource.com/go |
        grep -oP 'refs/tags/go\K[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -V | tail -n 1
}

# Node.js: newest LTS release, like "nvm install lts/*" in the node feature
node_lts() {
    curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts)][0].version'
}

# Deno: newest LTS release, like "deno upgrade lts" and the deno feature
deno_lts() {
    curl -fsSL https://dl.deno.land/release-lts-latest.txt ||
        curl -fsSL https://dl.deno.land/release-latest.txt
}

github_release() {
    gh release view --repo "$1" --json tagName --jq .tagName
}

probe go go_latest
probe node node_lts
probe deno deno_lts
probe pnpm npm view pnpm version
probe nvm github_release nvm-sh/nvm
probe golangci-lint github_release golangci/golangci-lint
probe prettier npm view prettier version
probe prettier-plugin-tailwindcss npm view prettier-plugin-tailwindcss version
