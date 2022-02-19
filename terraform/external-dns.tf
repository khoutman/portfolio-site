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
