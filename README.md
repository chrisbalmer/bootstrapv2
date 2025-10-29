# bootstrapv2

Talos Linux configuration for a single-node Kubernetes bootstrap cluster running on Raspberry Pi 5.

## Overview

This repository contains the configuration and tooling to manage a Talos Linux node named `bootstrapv2` with IP `172.21.7.100/24`.

## Hardware

- **Platform**: Raspberry Pi 5
- **OS**: Talos Linux
- **Node Name**: bootstrapv2
- **Node IP**: 172.21.7.100/24

## Prerequisites

- [talosctl](https://www.talos.dev/latest/introduction/getting-started/) - Talos CLI tool
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI tool

### Installing talosctl

```bash
brew install siderolabs/tap/talosctl
```

## Quick Start

1. **Generate initial configuration**:
   ```bash
   make generate-config
   ```

2. **Apply configuration to the node**:
   ```bash
   make apply-config
   ```

3. **Bootstrap Kubernetes**:
   ```bash
   make bootstrap
   ```

4. **Get kubeconfig**:
   ```bash
   make kubeconfig
   ```

## Configuration Parameters

The Makefile supports the following configurable parameters:

- **NODE_IP** - IP address of the Talos node (default: `172.21.7.100`)
- **TALOS_VERSION** - Talos version to use (default: `v1.10.7-1-g31471348f`)

You can override these when running make commands:

```bash
# Use a different node IP
make apply-config NODE_IP=172.21.7.101

# Use a different Talos version for upgrade
make upgrade TALOS_VERSION=v1.11.0 NODE_IP=172.21.7.100

# Override both parameters
make status NODE_IP=172.21.7.101
```

## Directory Structure

```
.
├── README.md                 # This file
├── Makefile                  # Common operations
├── configs/                  # Generated Talos configs
│   ├── controlplane.yaml    # Control plane configuration
│   └── talosconfig          # Talos client configuration
└── scripts/                  # Helper scripts
    └── patch.yaml           # Configuration patches
```

## Configuration

The node is configured with:
- Hostname: `bootstrapv2`
- IP Address: `172.21.7.100/24` (configurable via `NODE_IP` parameter)
- Single control plane node (no workers)
- ARM64 architecture for Raspberry Pi 5
- Custom Talos installer: `ghcr.io/chrisbalmer/installer:v1.10.7-1-g31471348f`
- Install disk: `/dev/nvme0n1`
- Network interface: `end0`
- DNS: Cloudflare family-friendly (1.1.1.3, 1.0.0.3)
- CNI: Antrea v2.4.3

## Common Operations

### Generate Secrets (First Time Setup)

⚠️ **Warning**: Only do this once when setting up a new cluster! Regenerating secrets will make your existing cluster inaccessible.

```bash
# Generate new secrets for Talos version 1.11.3
talosctl gen secrets --output-file configs/secrets.yaml --talos-version v1.11.3

# Store in 1Password
op document create configs/secrets.yaml --title "bootstrapv2-talos-secrets" --vault "homelab"
```

**Important Notes:**
- These secrets contain the cryptographic keys for your cluster
- **Never regenerate secrets for an existing cluster** - you will lose access to all nodes and data
- The secrets are automatically pulled from 1Password when running `make generate-config`
- If you need to regenerate for a fresh cluster installation, delete the old secrets from 1Password first

### Pull Secrets from 1Password

```bash
make pull-secrets
```

This retrieves the stored secrets from 1Password. This happens automatically when running `make generate-config`.

### Generate Configuration

```bash
make generate-config
```

This generates the Talos configuration files using the secrets stored in 1Password. The secrets ensure consistency across configuration regenerations.

### Apply Configuration

```bash
make apply-config
```

Applies the configuration to the node. Use this after making changes to the configuration.

### Bootstrap Kubernetes

```bash
make bootstrap
```

Bootstraps the Kubernetes cluster. Only run this once on initial setup.

### Get Kubeconfig

```bash
make kubeconfig
```

Retrieves the kubeconfig and merges it with your local kubectl config.

### Check Node Status

```bash
make status
```

### Upgrade Talos

```bash
make upgrade TALOS_VERSION=v1.10.7-1-g31471348f
```

Note: This uses a custom Talos installer image (`ghcr.io/chrisbalmer/installer`) optimized for this setup.

### Reset Node

```bash
make reset
```

⚠️ **Warning**: This will completely wipe the node!

## Troubleshooting

### Check node health

```bash
talosctl --nodes 172.21.7.100 health
```

### View logs

```bash
talosctl --nodes 172.21.7.100 logs
```

### Get service status

```bash
talosctl --nodes 172.21.7.100 services
```

### Access dashboard

```bash
talosctl --nodes 172.21.7.100 dashboard
```

## Network Configuration

The node uses static IP configuration:
- IP: 172.21.7.100/24
- Gateway: 172.21.7.1 (adjust in patch.yaml if different)
- DNS: 1.1.1.1, 8.8.8.8

## Notes

- This is a single-node cluster suitable for development and testing
- The control plane node will also run workloads (no taints)
- Optimized for ARM64 architecture (Raspberry Pi 5)

## Resources

- [Talos Documentation](https://www.talos.dev/)
- [Talos on Raspberry Pi](https://www.talos.dev/latest/talos-guides/install/single-board-computers/rpi_generic/)
