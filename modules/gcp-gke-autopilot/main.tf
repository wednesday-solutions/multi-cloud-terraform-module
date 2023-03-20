resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.application_name}-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.application_name}-subnetwok"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = var.subnet_cidr_range
}

resource "google_container_cluster" "primary" {
  name     = var.application_name
  location = var.region

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  ip_allocation_policy {}

  enable_autopilot = true
}
