output "region" {
  value = local.region
}

output "cluster_name" {
  value = module.gcp_gke.cluster_name
}
