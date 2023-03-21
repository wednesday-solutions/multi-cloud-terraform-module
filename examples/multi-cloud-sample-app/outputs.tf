output "ingress_name" {
  value = "${helm_release.eks_2048.name}-${helm_release.eks_2048.chart}"
}
