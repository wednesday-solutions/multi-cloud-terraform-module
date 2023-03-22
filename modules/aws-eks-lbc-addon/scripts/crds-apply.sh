aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
kubectl apply -k "$CRDS"