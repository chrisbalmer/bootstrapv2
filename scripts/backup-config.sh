#!/usr/bin/env bash

set -euo pipefail

NODE_IP="172.21.7.100"
TALOSCONFIG="configs/talosconfig"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

echo "=== Talos Configuration Backup Script ==="
echo "Creating backup in: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

# Backup local configs
if [ -d "configs" ]; then
    echo "Backing up local configuration files..."
    cp -r configs/* "$BACKUP_DIR/"
fi

# Get running configuration from node
echo "Retrieving running configuration from node..."
talosctl --nodes "$NODE_IP" \
    --endpoints "$NODE_IP" \
    --talosconfig "$TALOSCONFIG" \
    get mc v1alpha1 -o yaml > "$BACKUP_DIR/machine-config.yaml"

echo "Retrieving node metadata..."
talosctl --nodes "$NODE_IP" \
    --endpoints "$NODE_IP" \
    --talosconfig "$TALOSCONFIG" \
    get members -o yaml > "$BACKUP_DIR/members.yaml"

echo ""
echo "Backup completed successfully!"
echo "Location: $BACKUP_DIR"
echo ""
echo "To restore:"
echo "  talosctl apply-config --nodes $NODE_IP --file $BACKUP_DIR/controlplane.yaml"
