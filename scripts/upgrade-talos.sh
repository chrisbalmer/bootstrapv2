#!/usr/bin/env bash

set -euo pipefail

NODE_IP="172.21.7.100"
TALOSCONFIG="configs/talosconfig"

# Default version
VERSION="${1:-v1.8.0}"

echo "=== Talos Upgrade Script ==="
echo "Node: $NODE_IP"
echo "Target Version: $VERSION"
echo ""

# Check current version
echo "Current version:"
talosctl --nodes "$NODE_IP" \
    --endpoints "$NODE_IP" \
    --talosconfig "$TALOSCONFIG" \
    version --short

echo ""
read -p "Proceed with upgrade to $VERSION? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Upgrade cancelled"
    exit 0
fi

echo ""
echo "Starting upgrade..."
talosctl --nodes "$NODE_IP" \
    --endpoints "$NODE_IP" \
    --talosconfig "$TALOSCONFIG" \
    upgrade \
    --image "ghcr.io/siderolabs/installer:$VERSION" \
    --preserve

echo ""
echo "Upgrade initiated. The node will reboot."
echo "Monitor progress with: talosctl --nodes $NODE_IP --endpoints $NODE_IP --talosconfig $TALOSCONFIG dmesg -f"
