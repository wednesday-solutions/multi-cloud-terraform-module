output "region" {
  value = local.region
}


output "cluster_name" {
  value = module.aws_eks.cluster_name
}

output "vpc_id" {
  value = module.aws_eks_vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.aws_eks_vpc.public_subnet_ids
}
