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
    token: ${token}
