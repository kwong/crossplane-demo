# GKE — Terraform

This folder contains the Terraform code for the GKE cluster.

Quick start

```bash
export PROJECT_ID=your-gcp-project-id
cd infrastructure/gke
terraform init
terraform plan -var "project_id=$PROJECT_ID"
terraform apply -var "project_id=$PROJECT_ID"
```

Use the `kubeconfig_command` output to populate local kubeconfig (or run `gcloud container clusters get-credentials <name> --zone ${var.zone} --project $PROJECT_ID`).

Notes
- Defaults: `region=asia-southeast1`, `zone=asia-southeast1-a`.
- For production, add remote state (GCS backend), service accounts and IAM bindings, and regional/private clusters.

 - `workload_identity_service_account = "crossplane-gsa"`
 - `workload_identity_ksa_namespace = "crossplane-system"`
 - `workload_identity_ksa_name = "crossplane-provider-upjet-gcp"`

When `workload_identity_enable = true` Terraform will create a Google Service Account (GSA) and assign the following roles to it at the project level to allow Crossplane to manage resources:

- `roles/compute.networkAdmin`
- `roles/container.admin`
- `roles/iam.serviceAccountUser`
- `roles/iam.securityAdmin`
- `roles/iam.serviceAccountAdmin`
- `roles/iam.serviceAccountKeyAdmin`
- `roles/cloudsql.admin`

If you prefer more restrictive permissions, adjust the roles in `main.tf` accordingly before applying.

After `terraform apply`, use the `workload_identity_gsa_email` output and either add it to your Helm chart values as `workloadIdentity.gsaEmail`, or annotate an existing KSA:

```bash
# Example: annotate an existing KSA to use the GSA (runs on the cluster)
kubectl -n crossplane-system annotate serviceaccount ${WORKLOAD_KSA} \
	iam.gke.io/gcp-service-account=${WORKLOAD_GSA_EMAIL}
```

If for some reason you do not want Workload Identity, set `workload_identity_enable = false` in your TF variables. Workload Identity avoids storing long-lived JSON keys in the cluster and is the recommended approach for GKE.
