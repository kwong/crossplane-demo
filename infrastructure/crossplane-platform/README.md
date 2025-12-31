# crossplane-platform Helm chart

This is a small meta-chart that installs Crossplane and the GCP provider via upstream charts.

Prerequisites
- Helm 3.8+
- Add the Crossplane Helm repo and update dependencies:

```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
cd charts/crossplane-platform
helm dependency update
```

Create the provider secret (example):

```bash
kubectl -n crossplane-system create secret generic gcp-creds --from-file=creds=/path/to/key.json
```

Install the chart (this will install Crossplane; provider installation is optional):

```bash
helm install crossplane-platform ./charts/crossplane-platform --namespace crossplane-system --create-namespace
```

Notes & safety
- The chart will not store credentials in the chart; it references the secret you create.
- Verify upstream chart versions and provider API versions; adjust `values.yaml` accordingly.
- To configure provider package version or other upstream chart options, either enable `providerPackage.createProvider` to render a `Provider` resource from this chart, or install the upstream `provider-upjet-gcp` chart separately and configure it accordingly.

Post-install
- Confirm Crossplane is running: `kubectl get pods -n crossplane-system`
- Confirm provider is installed: `kubectl get providers.pkg.crossplane.io -A` or `kubectl get packages -A` depending on your setup.

Provider package resource
-------------------------

This chart can optionally render a Crossplane `Provider` resource that points at a provider package image (e.g., `registry.upbound.io/upbound/provider-upjet-gcp:v2.4.0`). By default this is disabled to avoid duplicating resources created by upstream provider charts. To enable it:

```bash
helm upgrade --install crossplane-platform ./ --set providerPackage.createProvider=true \
	--set providerPackage.package=registry.upbound.io/upbound/provider-upjet-gcp:v2.4.0 -n crossplane-system
```

If you install the upstream `provider-upjet-gcp` chart separately, it may already provide the package resource, so enabling this option is generally only necessary when you manage provider packages directly via this meta-chart.

ProviderConfig note
-------------------

This chart can render an example `ProviderConfig` for `provider-upjet-gcp` when `generateProviderConfig=true`. To avoid Helm failing when provider CRDs are not yet installed, the chart will only render the `ProviderConfig` if you also enable one of the following:

- `providerPackage.createProvider=true` (this chart renders a `Provider` package resource and installs the package), or
- enable the upstream `provider-upjet-gcp` chart separately so its CRDs are present (set `provider-upjet-gcp.enabled=true` when using that chart).

If you prefer, you can keep `generateProviderConfig=true` and install the provider package first, then run `helm upgrade --install` for this chart.

Workload Identity (optional)

This chart supports Workload Identity by either:

- letting Terraform create the Google Service Account (GSA) and IAM binding (see `infrastructure/gke/` outputs `workload_identity_gsa_email`), then setting that email in the chart via `--set workloadIdentity.gsaEmail=...` and enabling `workloadIdentity.createKSA=true` to have the chart create and annotate a Kubernetes ServiceAccount, or
- annotating an existing KSA (e.g., the provider controller's service account) manually using the GSA email from Terraform:

```bash
# Example: annotate an existing KSA to use the GSA (replace <ksa-name> if needed)
kubectl -n crossplane-system annotate serviceaccount <ksa-name> \
	iam.gke.io/gcp-service-account=${WORKLOAD_GSA_EMAIL}

# Or install the chart and create+annotate the KSA via Helm values
helm upgrade --install crossplane-platform ./ --set workloadIdentity.createKSA=true \
	--set workloadIdentity.gsaEmail="$(terraform -chdir=../gke output -raw workload_identity_gsa_email)" \
	-n crossplane-system
```

Notes
- The chart does not create GSA or IAM bindings; terraform `infrastructure/gke` can create them when `workload_identity_enable = true` (see `variables.tf`).
- Workload Identity is recommended for GKE because it avoids storing long-lived JSON keys in Kubernetes and integrates with GCP IAM.

ProviderConfig with InjectedIdentity

If you use Workload Identity, enable `providerConfig.useInjectedIdentity=true` when installing the chart so the rendered `ProviderConfig` uses `credentials.source: InjectedIdentity` instead of referencing a secret:

```bash
helm upgrade --install crossplane-platform ./ --set providerConfig.useInjectedIdentity=true \
	--set workloadIdentity.createKSA=true --set workloadIdentity.gsaEmail="${WORKLOAD_GSA_EMAIL}" -n crossplane-system
```

Note: check your installed `provider-upjet-gcp` API version and set `providerConfig.apiVersion` accordingly (e.g., `gcp.crossplane.io/v1beta1`).

## Authentication modes

You can authenticate the `provider-upjet-gcp` in one of two ways. Choose the one that matches your security posture.

- **Secret-based (default)** ✅
	- Create a Kubernetes Secret containing a GCP service account JSON and install the chart with the secret values (the chart will render a `ProviderConfig` that references the secret):

```bash
kubectl -n crossplane-system create secret generic gcp-creds --from-file=creds=/path/to/key.json
helm upgrade --install crossplane-platform ./ --set generateProviderConfig=true -n crossplane-system
```

- **Workload Identity (recommended for GKE)** 🔒
	- Use Workload Identity to avoid storing long-lived JSON keys in Kubernetes. Steps:
		1. Use Terraform (`infrastructure/gke`) to create a Google Service Account (GSA) and an IAM binding by setting `workload_identity_enable = true` and applying.
		2. Pass the GSA email to the chart and either let the chart create+annotate a Kubernetes ServiceAccount (KSA) or annotate an existing KSA yourself.

Example (create KSA + use InjectedIdentity):

```bash
# Get GSA email from Terraform outputs
GSA_EMAIL=$(terraform -chdir=../../gke output -raw workload_identity_gsa_email)

helm upgrade --install crossplane-platform ./ \
	--set providerConfig.useInjectedIdentity=true \
	--set workloadIdentity.createKSA=true \
	--set workloadIdentity.gsaEmail="$GSA_EMAIL" \
	-n crossplane-system
```

Or annotate an existing KSA manually:

```bash
kubectl -n crossplane-system annotate serviceaccount <ksa-name> \
	iam.gke.io/gcp-service-account=${GSA_EMAIL}
```

## Verify installation

- Check Crossplane and provider pods:

```bash
kubectl get pods -n crossplane-system
kubectl get providers.pkg.crossplane.io -A
```

- Confirm the `ProviderConfig` exists and has the expected credentials source:

```bash
kubectl -n crossplane-system get providerconfig -o yaml
# Look for `credentials.source: Secret` or `credentials.source: InjectedIdentity`
```

## Troubleshooting tips

- If provider reconciliation is failing, check provider and controller logs:

```bash
kubectl logs -n crossplane-system -l app.kubernetes.io/instance=provider-upjet-gcp --tail=200
kubectl logs -l app=crossplane -n crossplane-system --tail=200
```

- Workload Identity problems: ensure the GSA has `roles/iam.workloadIdentityUser` binding for the KSA member, and that the KSA annotation `iam.gke.io/gcp-service-account` matches the GSA email.
- If using Secret-based auth, verify the secret key name (`creds` by default) matches `values.providerCredentials.secretKey` / ProviderConfig template.

If you'd like, I can add a small CI workflow that runs `helm lint` and `terraform validate` to catch common installation problems early.
