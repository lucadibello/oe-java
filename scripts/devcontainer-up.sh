#!/usr/bin/env bash
set -euo pipefail

[ -f ".devcontainer.env" ] && source ".devcontainer.env"

IMAGE_NAME=${IMAGE_NAME:-my-devcontainer}
CONTAINER_NAME=${CONTAINER_NAME:-devcontainer}
WORKDIR=${WORKDIR:-/workspaces/project}
SSH_BIND_HOST=${SSH_BIND_HOST:-127.0.0.1}
NVIM_BIND_HOST=${NVIM_BIND_HOST:-127.0.0.1}
SSH_PORT=${SSH_PORT:-2222}
NVIM_REMOTE_PORT=${NVIM_REMOTE_PORT:-6666}
DEV_USERNAME=${DEV_USERNAME:-dev}
DEV_UID=${DEV_UID:-1000}
DEV_GID=${DEV_GID:-1000}
SSH_PUBKEY=${SSH_PUBKEY:-}
GIT_USER_NAME=${GIT_USER_NAME:-}
GIT_USER_EMAIL=${GIT_USER_EMAIL:-}

# if no SSH key provided (passed as text, not filepath), exit with error message
if [ -z "${SSH_PUBKEY// /}" ]; then
  echo "Error: SSH_PUBKEY environment variable is not set. Please set it to your public SSH key."
  exit 1
fi
if ! echo "$SSH_PUBKEY" | grep -Eq '^ssh-(rsa|ed25519|dss) '; then
  echo "Error: SSH_PUBKEY does not look like a valid SSH key."
  exit 1
fi

# Build if image missing
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  ./devcontainer-build.sh
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "Container $CONTAINER_NAME already exists. Starting…"
  docker start "$CONTAINER_NAME" >/dev/null
else
  # Map SSH only on loopback; mount repo; pass user IDs and key
  docker run -d \
    --name "$CONTAINER_NAME" \
    --ulimit memlock=-1:-1 \
    -p "${SSH_BIND_HOST}:${SSH_PORT}:22" \
    -p "${NVIM_BIND_HOST}:${NVIM_REMOTE_PORT}:6666" \
    -v "$PWD:${WORKDIR}:rw" \
    -e DEVUSER="$DEV_USERNAME" \
    -e DEVUID="$DEV_UID" \
    -e DEVGID="$DEV_GID" \
    -e SSH_PUBKEY="$SSH_PUBKEY" \
    -e GIT_USER_NAME="$GIT_USER_NAME" \
    -e GIT_USER_EMAIL="$GIT_USER_EMAIL" \
    --device /dev/sgx_enclave \
    --device /dev/sgx_provision \
    --device /dev/sgx_vepc \
    -w "${WORKDIR}" \
    "$IMAGE_NAME" >/dev/null
  echo "Started $CONTAINER_NAME"
fi

./scripts/devcontainer-ssh-info.sh
