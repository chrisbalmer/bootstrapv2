.PHONY: help generate-config apply-config bootstrap kubeconfig status upgrade reset clean

TALOS_VERSION ?= v1.8.0
NODE_IP := 172.21.7.100
CLUSTER_NAME := bootstrapv2
CLUSTER_ENDPOINT := https://$(NODE_IP):6443

help:
	@echo "Available targets:"
	@echo "  generate-config  - Generate initial Talos configuration"
	@echo "  apply-config     - Apply configuration to the node"
	@echo "  bootstrap        - Bootstrap the Kubernetes cluster (run once)"
	@echo "  kubeconfig       - Get and merge kubeconfig"
	@echo "  status           - Check node status"
	@echo "  health           - Check cluster health"
	@echo "  upgrade          - Upgrade Talos (specify VERSION=vX.Y.Z)"
	@echo "  reset            - Reset the node (WARNING: destructive)"
	@echo "  clean            - Remove generated configuration files"

generate-config:
	@echo "Generating Talos configuration..."
	@mkdir -p configs
	talosctl gen config $(CLUSTER_NAME) $(CLUSTER_ENDPOINT) \
		--output configs/ \
		--with-docs=false \
		--with-examples=false \
		--config-patch @scripts/patch.yaml
	@echo "Configuration generated in configs/"
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
	@echo "Upgrading Talos to $(TALOS_VERSION)..."
	talosctl --nodes $(NODE_IP) \
		--endpoints $(NODE_IP) \
		--talosconfig configs/talosconfig \
		upgrade \
		--image ghcr.io/siderolabs/installer:$(TALOS_VERSION)

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
