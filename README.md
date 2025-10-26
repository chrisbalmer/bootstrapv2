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
- IP Address: `172.21.7.100/24`
- Single control plane node (no workers)
- ARM64 architecture for Raspberry Pi 5

## Common Operations

### Generate Configuration

```bash
make generate-config
```

This generates the initial Talos configuration files.

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
make upgrade VERSION=v1.8.0
```

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
