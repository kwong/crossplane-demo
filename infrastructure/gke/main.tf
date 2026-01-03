resource "google_project_service" "enable_apis" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "sqladmin.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  # enable workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {}

  dynamic "addons_config" {
    for_each = []
    content {
    }
  }

  # lifecycle {
  #   ignore_changes = [node_pool]
  # }
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-node-pool-01"
  cluster  = google_container_cluster.primary.name
  location = var.zone

  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  # lifecycle {
  #   ignore_changes = [node_config]
  # }

}

// Optional: Workload Identity support - create a GSA and bind it to a KSA
resource "google_service_account" "crossplane" {
  count        = var.workload_identity_enable ? 1 : 0
  account_id   = var.workload_identity_service_account
  display_name = "Crossplane Workload Identity service account"
}

resource "google_service_account_iam_member" "ksa_workload_identity" {
  count = var.workload_identity_enable ? 1 : 0

  service_account_id = google_service_account.crossplane[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.workload_identity_ksa_namespace}/${var.workload_identity_ksa_name}]"
}

resource "google_project_iam_member" "gsa_owner" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}

// Additional project-level roles granted to the Crossplane GSA to enable
// provisioning and management of cluster and cloud resources (scoped to the
// project). These are added when `workload_identity_enable = true`.
resource "google_project_iam_member" "gsa_compute_network_admin" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}

resource "google_project_iam_member" "gsa_container_admin" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}

resource "google_project_iam_member" "gsa_iam_serviceAccountUser" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}

resource "google_project_iam_member" "gsa_iam_security_admin" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/iam.securityAdmin"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}

resource "google_project_iam_member" "gsa_iam_serviceAccountAdmin" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}

resource "google_project_iam_member" "gsa_iam_serviceAccountKeyAdmin" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountKeyAdmin"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}

resource "google_project_iam_member" "gsa_cloudsql_admin" {
  count   = var.workload_identity_enable ? 1 : 0
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.crossplane[0].email}"
}
