module "gcp_gke" {
  source = "../../modules/gcp-gke"

  project_id       = var.project_id
  application_name = "gke-test-cluster"
  region           = "asia-south1"
}
