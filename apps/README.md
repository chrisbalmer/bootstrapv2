# Applications

This directory contains ArgoCD Application definitions that will be automatically deployed to the cluster.

## Structure

```
apps/
├── root-app.yaml          # Root application (App of Apps pattern)
├── argocd.yaml            # ArgoCD managing itself
└── <app-name>/            # Future applications
    ├── application.yaml   # ArgoCD Application definition
    └── manifests/         # Kubernetes manifests
```

## How It Works

1. The `root-app.yaml` is applied once to bootstrap the system
2. ArgoCD watches the `apps/` directory for new applications
3. Any new YAML files in `apps/` are automatically deployed
4. Changes to application definitions are auto-synced

## Adding a New Application

Create a new Application resource in this directory:

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
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Then commit and push - ArgoCD will detect and deploy it automatically!
