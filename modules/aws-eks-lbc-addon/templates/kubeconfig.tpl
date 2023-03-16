apiVersion: v1
clusters:
- cluster:
    server: ${cluster_endpoint}
    certificate-authority-data: ${ca_certificate}
  name: ${cluster_name}
contexts:
- context:
    cluster: ${cluster_name}
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --region
      - ${region}
      - eks
      - get-token
      - --cluster-name
      - ${cluster_name}
      command: aws
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false
