module "alb_controller" {
  source  = "git::https://github.com/GSA/terraform-kubernetes-aws-load-balancer-controller?ref=v4.3.0gsa"

  providers = {
    kubernetes = "kubernetes.eks",
    helm       = "helm.eks"
  }

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = data.aws_region.current.name
  k8s_cluster_name = data.aws_eks_cluster.target.name
}
