# GitOps Workflow

This document explains how the GitOps workflow is set up and how to use it.

## Overview

The cluster uses ArgoCD with an **App of Apps** pattern to automatically deploy applications from this git repository.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  GitHub Repository (main branch)                        │
│  github.com/chrisbalmer/bootstrapv2                     │
│                                                          │
│  ├── apps/                                              │
│  │   ├── root-app.yaml    ← Watches this directory     │
│  │   ├── argocd.yaml      ← ArgoCD manages itself      │
│  │   └── my-app.yaml      ← Add new apps here          │
│  │                                                       │
│  └── bootstrap/argocd/    ← ArgoCD installation        │
└─────────────────────────────────────────────────────────┘
                        ↓
                   git pull (auto)
                        ↓
┌─────────────────────────────────────────────────────────┐
│  ArgoCD (running in cluster)                            │
│                                                          │
│  1. Polls git repo every 3 minutes                      │
│  2. Detects changes in apps/ directory                  │
│  3. Automatically applies new/changed applications      │
│  4. Self-heals if cluster state drifts from git         │
└─────────────────────────────────────────────────────────┘
                        ↓
                   kubectl apply
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                     │
│                                                          │
│  All applications deployed and managed by ArgoCD        │
└─────────────────────────────────────────────────────────┘
```

## Current Applications

- **root-app**: Watches the `apps/` directory for new Application resources
- **argocd**: ArgoCD managing its own installation (self-managed)

## How It Works

### 1. Root Application Watches Git

The `root-app` application is configured to:
- Monitor the `apps/` directory in this repository
- Auto-sync every 3 minutes (or on webhook trigger)
- Apply any new `.yaml` files as ArgoCD Applications
- Remove applications if their definition is deleted from git

### 2. Automated Deployment

When you:
1. Add a new `apps/my-app.yaml` file
2. Commit and push to `main` branch
3. ArgoCD automatically:
   - Detects the new file (within 3 minutes)
   - Creates the Application resource
   - Deploys the application to the cluster

### 3. Self-Healing

If someone manually changes something in the cluster that differs from git:
- ArgoCD automatically reverts it back to match git
- This ensures git is always the source of truth

## Adding a New Application

### Option 1: Simple Application

Create a file in `apps/` directory (e.g., `apps/nginx.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/chrisbalmer/bootstrapv2.git
    targetRevision: main
    path: apps/nginx/manifests  # Your k8s manifests here
  destination:
    server: https://kubernetes.default.svc
    namespace: nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Then create the manifests directory:

```bash
mkdir -p apps/nginx/manifests
# Add your Kubernetes manifests to apps/nginx/manifests/
```

Commit, push, and ArgoCD will deploy it!

### Option 2: Helm Chart

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-helm-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.example.com
    chart: my-chart
    targetRevision: 1.0.0
    helm:
      values: |
        replicas: 1
        service:
          type: ClusterIP
  destination:
    server: https://kubernetes.default.svc
    namespace: my-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Option 3: External Git Repository

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/some-org/some-repo.git
    targetRevision: main
    path: kubernetes/
  destination:
    server: https://kubernetes.default.svc
    namespace: external-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Viewing Applications

### CLI

```bash
# List all applications
kubectl get applications -n argocd

# Get application status
kubectl get application <app-name> -n argocd -o yaml
```

### Web UI

```bash
# Port forward to ArgoCD UI
make argocd-port-forward

# Get admin password
make argocd-password

# Open browser to http://localhost:8080
# Username: admin
# Password: (from make argocd-password)
```

## Sync Behavior

### Automatic Sync

All applications are configured with:

```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources not in git
    selfHeal: true   # Revert manual changes
```

This means:
- Changes pushed to git are deployed within 3 minutes
- Manual changes to the cluster are automatically reverted
- Deleted files in git result in deleted resources in cluster

### Manual Sync

If you want manual control, remove the `automated` section:

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
  # No automated section = manual sync required
```

Then sync manually via UI or CLI:

```bash
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

## Webhook for Instant Sync (Optional)

Instead of waiting 3 minutes, you can configure a webhook:

1. In GitHub repository settings → Webhooks → Add webhook
2. Payload URL: `https://your-argocd-server/api/webhook`
3. Content type: `application/json`
4. Secret: (from ArgoCD webhook secret)
5. Events: Just the push event

Now changes are deployed instantly on push!

## Monitoring

### Check Sync Status

```bash
# All apps
kubectl get applications -n argocd

# Detailed status
kubectl describe application <app-name> -n argocd
```

### Check Application Health

```bash
kubectl get application <app-name> -n argocd -o jsonpath='{.status.health.status}'
```

Possible values:
- `Healthy`: All resources are healthy
- `Progressing`: Deployment in progress
- `Degraded`: Some resources are unhealthy
- `Missing`: Expected resources not found

### Check Sync Status

```bash
kubectl get application <app-name> -n argocd -o jsonpath='{.status.sync.status}'
```

Possible values:
- `Synced`: Cluster matches git
- `OutOfSync`: Cluster differs from git

## Troubleshooting

### Application Not Syncing

```bash
# Check application status
kubectl describe application <app-name> -n argocd

# Force refresh
kubectl patch application <app-name> -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### View Application Logs

```bash
# ArgoCD application controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Reset Application

```bash
# Delete and let ArgoCD recreate
kubectl delete application <app-name> -n argocd
# Wait for root-app to recreate it from git
```

## Best Practices

1. **Always commit to git first**: Never manually apply to cluster
2. **Use feature branches**: Test changes before merging to main
3. **Keep apps/ directory organized**: Group related applications
4. **Use meaningful names**: Application names should be descriptive
5. **Monitor health**: Check ArgoCD UI regularly
6. **Document changes**: Add comments to Application resources

## Migration to Main Branch

Currently testing on `feature/argocd-bootstrap` branch. To migrate:

1. Update `apps/root-app.yaml` and `apps/argocd.yaml`:
   ```yaml
   targetRevision: main  # Change from feature/argocd-bootstrap
   ```

2. Commit and merge to main:
   ```bash
   git checkout main
   git merge feature/argocd-bootstrap
   git push origin main
   ```

3. ArgoCD will automatically switch to tracking main branch

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
