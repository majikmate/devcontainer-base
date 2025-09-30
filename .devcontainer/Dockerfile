ARG VARIANT="bookworm"
FROM buildpack-deps:${VARIANT}-curl

# --- Accept build-time values ---
ARG OCI_IMAGE_TITLE="DevContainer Base Environment"
ARG OCI_IMAGE_DESCRIPTION="Base Dev Container setup based on Debian 12 with custom user management and development tools"
ARG OCI_IMAGE_VERSION="dev"
ARG OCI_IMAGE_REVISION="unknown"
ARG OCI_IMAGE_REF_NAME="main"
ARG OCI_IMAGE_SOURCE="https://github.com/majikmate/devcontainer-base"
ARG OCI_IMAGE_URL="https://github.com/majikmate/devcontainer-base"
ARG OCI_IMAGE_DOCUMENTATION="https://github.com/majikmate/devcontainer-base#readme"
ARG OCI_IMAGE_CREATED=""
ARG OCI_IMAGE_AUTHORS="majikmate"
ARG OCI_IMAGE_VENDOR="majikmate"
ARG OCI_IMAGE_LICENSES="MIT"

# --- Bake them as runtime env (persist in image) ---
ENV OCI_IMAGE_TITLE="$OCI_IMAGE_TITLE" \
    OCI_IMAGE_DESCRIPTION="$OCI_IMAGE_DESCRIPTION" \
    OCI_IMAGE_VERSION="$OCI_IMAGE_VERSION" \
    OCI_IMAGE_REVISION="$OCI_IMAGE_REVISION" \
    OCI_IMAGE_REF_NAME="$OCI_IMAGE_REF_NAME" \
    OCI_IMAGE_SOURCE="$OCI_IMAGE_SOURCE" \
    OCI_IMAGE_URL="$OCI_IMAGE_URL" \
    OCI_IMAGE_DOCUMENTATION="$OCI_IMAGE_DOCUMENTATION" \
    OCI_IMAGE_CREATED="$OCI_IMAGE_CREATED" \
    OCI_IMAGE_AUTHORS="$OCI_IMAGE_AUTHORS" \
    OCI_IMAGE_VENDOR="$OCI_IMAGE_VENDOR" \
    OCI_IMAGE_LICENSES="$OCI_IMAGE_LICENSES"

# --- Also apply standard OCI labels (good practice) ---
LABEL org.opencontainers.image.title="$OCI_IMAGE_TITLE" \
      org.opencontainers.image.description="$OCI_IMAGE_DESCRIPTION" \
      org.opencontainers.image.version="$OCI_IMAGE_VERSION" \
      org.opencontainers.image.revision="$OCI_IMAGE_REVISION" \
      org.opencontainers.image.ref.name="$OCI_IMAGE_REF_NAME" \
      org.opencontainers.image.source="$OCI_IMAGE_SOURCE" \
      org.opencontainers.image.url="$OCI_IMAGE_URL" \
      org.opencontainers.image.documentation="$OCI_IMAGE_DOCUMENTATION" \
      org.opencontainers.image.created="$OCI_IMAGE_CREATED" \
      org.opencontainers.image.authors="$OCI_IMAGE_AUTHORS" \
      org.opencontainers.image.vendor="$OCI_IMAGE_VENDOR" \
      org.opencontainers.image.licenses="$OCI_IMAGE_LICENSES"