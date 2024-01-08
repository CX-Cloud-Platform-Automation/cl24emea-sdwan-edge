variable "gke_username" {
  default     = "admin"
  description = "GKE username"
}

variable "gke_password" {
  default     = "admin"
  description = "GKE password"
}

variable "gke_num_nodes" {
  default     = 5
  description = "Number of GKE nodes"
}

variable "k8s_version" {
  default     = "1.27.3-gke.100"
  description = "Version of the k8s cluster"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "multicloud-gke"
  location = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "sdwan-service-network"
  subnetwork = var.subnet_service

  release_channel {
    channel = "UNSPECIFIED"
  }
  min_master_version = var.k8s_version
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes
  version    = var.k8s_version

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project
    }

    # preemptible  = true
    machine_type = "n1-standard-8"
    tags         = ["gke-node", "multicloud-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  management {
    auto_upgrade = false
  }
}


# # Kubernetes provider
# # The Terraform Kubernetes Provider configuration below is used as a learning reference only.
# # It references the variables and resources provisioned in this file.
# # We recommend you put this in another file -- so you can have a more modular configuration.
# # https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster#optional-configure-terraform-kubernetes-provider
# # To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider.

# provider "kubernetes" {
#   load_config_file = "false"

#   host     = google_container_cluster.primary.endpoint
#   username = var.gke_username
#   password = var.gke_password

#   client_certificate     = google_container_cluster.primary.master_auth.0.client_certificate
#   client_key             = google_container_cluster.primary.master_auth.0.client_key
#   cluster_ca_certificate = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
# }