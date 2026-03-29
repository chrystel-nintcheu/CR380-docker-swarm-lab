#!/usr/bin/env bash
# =============================================================================
# CR380 — Provision a Multipass VM for Docker Swarm Labs
# =============================================================================
# Usage: bash cloud-init/provision-multipass.sh [vm-name]
# =============================================================================

set -euo pipefail

VM_NAME="${1:-cr380-swarm-lab}"
CLOUD_INIT="$(cd "$(dirname "$0")" && pwd)/user-data-fresh.yaml"

if ! command -v multipass &>/dev/null; then
    echo "ERROR: multipass is not installed. Install it from https://multipass.run"
    exit 1
fi

if [[ ! -f "${CLOUD_INIT}" ]]; then
    echo "ERROR: cloud-init file not found: ${CLOUD_INIT}"
    exit 1
fi

echo "==> Launching Multipass VM '${VM_NAME}'..."
multipass launch \
    --name "${VM_NAME}" \
    --cpus 2 \
    --memory 4G \
    --disk 20G \
    --cloud-init "${CLOUD_INIT}" \
    22.04

echo "==> Waiting for cloud-init to complete..."
multipass exec "${VM_NAME}" -- cloud-init status --wait

echo "==> VM '${VM_NAME}' is ready."
echo "    Connect with: multipass shell ${VM_NAME}"
echo "    Then run:     cd CR380-docker-swarm-lab && sudo bash run-labs.sh --learn"
