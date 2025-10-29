.PHONY: help generate-config apply-config bootstrap kubeconfig status upgrade reset clean

TALOS_VERSION ?= v1.10.7
INSTALLER_IMAGE ?= ghcr.io/chrisbalmer/installer:v1.10.7-1-g31471348f
NODE_IP ?= 172.21.7.100
CLUSTER_NAME := bootstrapv2
CLUSTER_ENDPOINT := https://$(NODE_IP):6443

help:
	@echo "Available targets:"
	@echo "  generate-config  - Generate initial Talos configuration"
	@echo "  pull-secrets     - Pull secrets from 1Password"
	@echo "  apply-config     - Apply configuration to the node"
	@echo "  bootstrap        - Bootstrap the Kubernetes cluster (run once)"
	@echo "  kubeconfig       - Get and merge kubeconfig"
	@echo "  status           - Check node status"
	@echo "  health           - Check cluster health"
	@echo "  upgrade          - Upgrade Talos (specify VERSION=vX.Y.Z)"
	@echo "  reset            - Reset the node (WARNING: destructive)"
	@echo "  clean            - Remove generated configuration files"

pull-secrets:
	@echo "Pulling secrets from 1Password..."
	@mkdir -p configs
	@op document get "bootstrapv2-talos-secrets" --vault "homelab" --output configs/secrets.yaml
	@echo "Secrets retrieved successfully"

generate-config: pull-secrets
	@echo "Generating Talos configuration for version $(TALOS_VERSION)..."
	@mkdir -p configs
	talosctl gen config $(CLUSTER_NAME) $(CLUSTER_ENDPOINT) \
		--output configs/ \
		--with-docs=false \
		--with-examples=false \
		--with-secrets configs/secrets.yaml \
		--config-patch @scripts/patch.yaml \
		--talos-version $(TALOS_VERSION)
	@echo "Configuring talosconfig with endpoint and node..."
	@yq eval -i '.contexts.$(CLUSTER_NAME).endpoints = ["$(NODE_IP)"]' configs/talosconfig
	@yq eval -i '.contexts.$(CLUSTER_NAME).nodes = ["$(NODE_IP)"]' configs/talosconfig
	@echo "Configuration generated in configs/"
	@echo "Talosconfig configured with endpoint and node: $(NODE_IP)"
	@echo "Review and customize configs/controlplane.yaml if needed"

apply-config:
	@echo "Applying configuration to node at $(NODE_IP)..."
	talosctl apply-config \
		--nodes $(NODE_IP) \
		--file configs/controlplane.yaml \
		--insecure
	@echo "Configuration applied successfully"

bootstrap:
	@echo "Bootstrapping Kubernetes cluster..."
	@sleep 5
	talosctl bootstrap \
		--nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig
	@echo "Bootstrap initiated. This may take a few minutes..."
	@echo "Check status with: make status"

kubeconfig:
	@echo "Retrieving kubeconfig..."
	talosctl kubeconfig \
		--nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		--force
	@echo "Kubeconfig merged to ~/.kube/config"
	@echo "Testing connection..."
	@kubectl get nodes

status:
	@echo "Node status:"
	@talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		get members
	@echo ""
	@echo "Kubernetes nodes:"
	@kubectl get nodes -o wide 2>/dev/null || echo "Kubernetes not ready yet"

health:
	@echo "Checking cluster health..."
	@talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		health

upgrade:
	@echo "Upgrading Talos to $(INSTALLER_IMAGE)..."
	talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		upgrade \
		--image $(INSTALLER_IMAGE)

reset:
	@echo "WARNING: This will completely wipe the node!"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		reset \
		--graceful=false \
		--reboot

clean:
	@echo "Removing generated configuration files..."
	rm -rf configs/
	@echo "Cleaned"

# Convenience targets
logs:
	@talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		logs

dashboard:
	@talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		dashboard

services:
	@talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		services
