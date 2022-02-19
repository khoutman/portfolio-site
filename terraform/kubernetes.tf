provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

# Namespaces

resource "kubernetes_namespace" "production-namespace" {
  metadata {
    name = "production"

    labels = {
      name = "production"
      environment = "production"
    }
  }
}

# ALB Ingress Controller
resource "kubernetes_service_account" "alb-ingress-controller" {
  metadata {
    name = "aws-alb-ingress-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kubernetes/aws-alb-ingress-controller"
    }

    labels = {
      "app.kubernetes.io/name" = "aws-alb-ingress-controller"
    }
  }

  automount_service_account_token = true

  depends_on = [
    aws_iam_policy.alb-ingress-controller-policy,
    aws_iam_role.alb-ingress-controller-role,
    aws_iam_role_policy_attachment.alb-ingress-controller-role-policy
  ]
}

resource "kubernetes_cluster_role" "alb-ingress-controller" {
  metadata {
    name = "aws-alb-ingress-controller"

    labels = {
      "app.kubernetes.io/name" = "aws-alb-ingress-controller"
    }
  }

  rule {
    api_groups = ["", "extensions"]
    resources = ["configmaps", "endpoints", "events", "ingresses", "ingresses/status", "services"]
    verbs = ["create", "get", "list", "update", "watch", "patch"]
  }

  rule {
    api_groups = ["", "extensions"]
    resources = ["nodes", "pods", "secrets", "services", "namespaces"]
    verbs = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "alb-ingress-controller" {
  metadata {
    name = "aws-alb-ingress-controller"

    labels = {
      "app.kubernetes.io/name" = "aws-alb-ingress-controller"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "aws-alb-ingress-controller"
  }

  subject {
    kind = "ServiceAccount"
    name = "aws-alb-ingress-controller"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "alb-ingress-controller" {
  metadata {
    name = "aws-alb-ingress-controller"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name" = "aws-alb-ingress-controller"
    }
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "aws-alb-ingress-controller"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "aws-alb-ingress-controller"
        }
      }

      spec {
        container {
          name = "aws-alb-ingress-controller"
          image = "docker.io/amazon/aws-alb-ingress-controller:v1.1.4"
          args = [
            "--ingress-class=alb",
            "--cluster-name=${local.cluster_name}",
            "--aws-vpc-id=${data.aws_vpc.application-vpc.id}",
            "--aws-region=us-east-1"
          ]
        }

        automount_service_account_token = true

        service_account_name = "aws-alb-ingress-controller"
      }
    }
  }

  depends_on = [
    aws_iam_policy.alb-ingress-controller-policy,
    aws_iam_role.alb-ingress-controller-role,
    aws_iam_role_policy_attachment.alb-ingress-controller-role-policy
  ]
}

# External DNS

resource "kubernetes_service_account" "external-dns" {
  metadata {
    name = "external-dns"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "external-dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources = ["services"]
    verbs = ["get", "watch", "list"]
  }

  rule {
    api_groups = [""]
    resources = ["pods"]
    verbs = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["extensions"]
    resources = ["ingresses"]
    verbs = ["get", "watch", "list"]
  }

  rule {
    api_groups = [""]
    resources = ["nodes"]
    verbs = ["list"]
  }

  rule {
    api_groups = [""]
    resources = ["endpoints"]
    verbs = ["get", "watch", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "external-dns" {
  metadata {
    name = "external-dns"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "external-dns"
  }

  subject {
    kind = "ServiceAccount"
    name = "external-dns"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "external-dns" {
  metadata {
    name = "external-dns"
    namespace = "kube-system"
  }

  spec {
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "name" = "external-dns"
      }
    }

    template {
      metadata {
        labels = {
          name = "external-dns"
        }
      }

      spec {
        container {
          name = "external-dns"
          image = "bitnami/external-dns:latest"
          args = [
            "--source=service",
            "--source=ingress",
            "--provider=aws",
            "--aws-zone-type=public",
            "--registry=txt",
            "--txt-owner-id=my-id"
          ]
        }

        automount_service_account_token = true

        service_account_name = "external-dns"
      }
    }
  }

  depends_on = [
    aws_iam_policy.alb-ingress-controller-policy,
    aws_iam_role.alb-ingress-controller-role,
    aws_iam_role_policy_attachment.alb-ingress-controller-role-policy
  ]
}
