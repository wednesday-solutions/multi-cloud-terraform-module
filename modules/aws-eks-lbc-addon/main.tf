data "tls_certificate" "cluster" {
  url = var.cluster_oidc_issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url             = data.tls_certificate.cluster.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.cluster.certificates[*].sha1_fingerprint
}

data "http" "lb_controll_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${var.application_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.lb_controll_iam_policy.response_body
}

data "aws_iam_policy_document" "lb_trust_policy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${var.application_name}-AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.lb_trust_policy.json
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "lb_controller_iam_policy" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

resource "kubernetes_service_account" "lb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }
}

# Install helm chart for aws-load-balancer-controller

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = "kube-system"

  dynamic "set" {
    for_each = {
      "clusterName"           = var.cluster_name
      "serviceAccount.create" = false
      "serviceAccount.name"   = "aws-load-balancer-controller"
      "region"                = var.region
      "vpcId"                 = var.vpc_id
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/templates/kubeconfig.tpl",
    {
      cluster_endpoint = var.cluster_endpoint
      ca_certificate   = var.cluster_ca_certificate
      cluster_name     = var.cluster_name
      token            = var.cluster_token
    }
  )
  filename = "${path.module}/${var.cluster_name}.kubeconfig.yaml"
}

# Install TargetGroupBinding CRDs

resource "null_resource" "target_group_binding_crds" {

  triggers = {
    albc_tgb_crds_path = "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
    kubeconfig_path    = local_file.kubeconfig.filename
  }

  provisioner "local-exec" {
    command = "kubectl apply -k \"${self.triggers.albc_tgb_crds_path}\" "

    environment = {
      KUBECONFIG = self.triggers.kubeconfig_path
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -k \"${self.triggers.albc_tgb_crds_path}\" "

    environment = {
      KUBECONFIG = self.triggers.kubeconfig_path
    }
  }
}
