data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "tls_certificate" "cluster" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
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
      "vpcId"                 = data.aws_eks_cluster.cluster.vpc_config.0.vpc_id
    }
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_service_account.lb_controller_sa,
    aws_iam_role_policy_attachment.lb_controller_iam_policy
  ]
}

# Install TargetGroupBinding CRDs

resource "null_resource" "target_group_binding_crds" {
  triggers = {
    albc_tgb_crds_path = "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
    region             = var.region
    cluster_name       = var.cluster_name
    cluster_arn        = data.aws_eks_cluster.cluster.arn
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/crds-apply.sh"
    environment = {
      REGION       = self.triggers.region
      CLUSTER_NAME = self.triggers.cluster_name
      CRDS         = self.triggers.albc_tgb_crds_path
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/unset-context.sh"

    environment = {
      CLUSTER_ARN = self.triggers.cluster_arn
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}
