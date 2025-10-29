# Quick Reference: Adding a New Application

## Simple 3-Step Process

### 1. Create Application Definition

Create `apps/my-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/chrisbalmer/bootstrapv2.git
    targetRevision: main
    path: apps/my-app/manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 2. Create Your Manifests

```bash
mkdir -p apps/my-app/manifests
```

Add your Kubernetes manifests to `apps/my-app/manifests/`:
- `deployment.yaml`
- `service.yaml`
- `configmap.yaml`
- etc.

### 3. Commit and Push

```bash
git add apps/my-app/
git commit -m "feat: add my-app"
git push
```

**That's it!** ArgoCD will automatically deploy within 3 minutes.

## Verify Deployment

```bash
# Check application status
kubectl get applications -n argocd

# Check pods
kubectl get pods -n my-app

# View in UI
make argocd-port-forward
# Open http://localhost:8080
```

## Common Patterns

### Using Helm Chart

```yaml
source:
  repoURL: https://charts.bitnami.com/bitnami
  chart: nginx
  targetRevision: 15.0.0
  helm:
    values: |
      replicaCount: 1
```

### Using Kustomize

```yaml
source:
  repoURL: https://github.com/chrisbalmer/bootstrapv2.git
  targetRevision: main
  path: apps/my-app/base
  kustomize:
    namePrefix: prod-
```

### External Repository

```yaml
source:
  repoURL: https://github.com/kubernetes/examples.git
  targetRevision: master
  path: guestbook
```

## Full Documentation

See [docs/GITOPS.md](../docs/GITOPS.md) for complete documentation.
