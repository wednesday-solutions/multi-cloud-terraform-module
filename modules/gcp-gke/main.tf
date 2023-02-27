provider "google" {
  project = var.project_id
  region  = var.region

}

resource "google_container_cluster" "cluster" {
  name     = "${var.application_name}-cluster"
  location = var.region

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  enable_autopilot = true
}
