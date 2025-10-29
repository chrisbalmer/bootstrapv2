# ArgoCD Bootstrap

This directory contains the configuration to bootstrap ArgoCD on the cluster.

## Installation

### Using Makefile

```bash
make bootstrap-argocd
```

### Manual Installation

```bash
kubectl apply -k bootstrap/argocd/
```

## Initial Setup

1. **Wait for ArgoCD to be ready**:
   ```bash
   kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
   ```

2. **Get the initial admin password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Access ArgoCD UI**:
   
   **Port Forward:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   
   Then open: http://localhost:8080
   
   **Or using the Makefile:**
   ```bash
   make argocd-port-forward
   ```

4. **Login**:
   - Username: `admin`
   - Password: (from step 2)

5. **Change the admin password**:
   ```bash
   argocd account update-password
   ```

## ArgoCD CLI

### Install ArgoCD CLI

```bash
brew install argocd
```

### Login to ArgoCD

```bash
# Port forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Login (use password from above)
argocd login localhost:8080 --username admin --insecure
```

## Configuration

The installation includes:

- **Namespace**: `argocd`
- **Mode**: Single replica (suitable for single-node cluster)
- **Server**: Insecure mode enabled (no TLS internally)
- **Version**: v2.13.2

### Customization

To customize the installation:

1. Edit `bootstrap/argocd/install.yaml` for ArgoCD configuration
2. Edit `bootstrap/argocd/kustomization.yaml` for resource patches
3. Apply changes:
   ```bash
   kubectl apply -k bootstrap/argocd/
   ```

## Post-Installation

### Create an Application

Example app-of-apps pattern:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Uninstallation

```bash
kubectl delete -k bootstrap/argocd/
```

Or using Makefile:

```bash
make remove-argocd
```

## Troubleshooting

### Check ArgoCD Status

```bash
kubectl get pods -n argocd
```

### View ArgoCD Logs

```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server
kubectl logs -n argocd statefulset/argocd-application-controller
```

### Reset Admin Password

```bash
kubectl -n argocd patch secret argocd-secret -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'
kubectl -n argocd rollout restart deployment argocd-server
```

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
