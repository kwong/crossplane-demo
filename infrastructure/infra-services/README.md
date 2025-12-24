# infra-services / crossplane

This folder contains Crossplane artifacts and two Helm charts:

- `charts/infra-services/` — packages `ProviderConfig` and `Composition` manifests (CloudSQL by default).
- `charts/crossplane-platform/` — meta-chart that installs Crossplane; provider installation is optional (see chart README).

Quick examples

```bash
# Create provider secret (do NOT store secrets in git)
kubectl -n crossplane-system create secret generic gcp-creds --from-file=creds=/path/to/key.json

# Install CRDs for the infra-services chart (CloudSQL XRD)
kubectl apply -f charts/infra-services/crds/100-cloudsql-xrd.yaml

# Install infra-services chart (compositions)
helm install infra-services ./charts/infra-services --namespace crossplane-system --create-namespace

# Install Crossplane via the meta-chart (provider installation optional)
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
cd charts/crossplane-platform
helm dependency update
helm install crossplane-platform ./ --namespace crossplane-system --create-namespace
```

Notes & safety

- The charts reference existing secrets and do not embed credentials — use sealed-secrets or external secret stores if you want to store encrypted secrets in git.
- Verify upstream chart versions and provider API versions; update `charts/crossplane-platform/Chart.yaml` and charts `values.yaml` as needed.
