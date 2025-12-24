variable "project_id" {
  type        = string
  description = "GCP project id where GKE cluster will be created"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "asia-southeast1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "asia-southeast1-a"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
  default     = "demo-gke"
}

variable "network" {
  type        = string
  description = "VPC network name"
  default     = "default"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork name"
  default     = "default"
}

variable "node_count" {
  type        = number
  description = "Initial node count for the primary node pool"
  default     = 1
}

variable "machine_type" {
  type        = string
  description = "Machine type for nodes"
  default     = "e2-medium"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes master version (leave empty for default)"
  default     = ""
}

variable "workload_identity_enable" {
  type        = bool
  description = "Whether to create a Google service account and bind it for Workload Identity"
  default     = true
}

variable "workload_identity_service_account" {
  type        = string
  description = "Google Service Account name (id) to create for Workload Identity"
  default     = "crossplane-gsa"
}

variable "workload_identity_ksa_namespace" {
  type        = string
  description = "Kubernetes namespace containing the ServiceAccount that will impersonate the GSA"
  default     = "crossplane-system"
}

variable "workload_identity_ksa_name" {
  type        = string
  description = "Kubernetes ServiceAccount name that will impersonate the GSA"
  default     = "crossplane-provider-gcp"
}
