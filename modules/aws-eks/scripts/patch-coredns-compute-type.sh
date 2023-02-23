#!/bin/sh

# Set kubectl context to current EKS cluster
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Patch CoreDNS pods annotation 
# eks.amazonaws.com/compute-type = ec2 -> fargate
kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{ "op": "replace", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type", "value": "fargate" }]'
