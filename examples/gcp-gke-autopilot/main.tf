locals {
  region = "asia-southeast1"
}

provider "google" {
  project = var.project_id
  region  = local.region
}

module "gcp_gke" {
  source = "../../modules/gcp-gke-autopilot"

  project_id       = var.project_id
  application_name = "gke-test-cluster"
  region           = local.region

  subnet_cidr_range = "10.0.0.0/16"
}
