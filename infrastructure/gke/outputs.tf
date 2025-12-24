output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "kubernetes_endpoint" {
  description = "Cluster endpoint (master)"
  value       = google_container_cluster.primary.endpoint
}

output "kubeconfig_command" {
  description = "Command to populate local kubeconfig for this cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}

output "workload_identity_gsa_email" {
  description = "Email of the GSA created for Workload Identity (if enabled)"
  value       = var.workload_identity_enable ? google_service_account.crossplane[0].email : ""
}

output "workload_identity_binding_member" {
  description = "Member string used in the IAM binding (serviceAccount:<PROJECT>.svc.id.goog[<ns>/<ksa>])"
  value       = "serviceAccount:${var.project_id}.svc.id.goog[${var.workload_identity_ksa_namespace}/${var.workload_identity_ksa_name}]"
}
