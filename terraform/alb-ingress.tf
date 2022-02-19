module "alb_controller" {

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  source           = "git::https://github.com/GSA/terraform-kubernetes-aws-load-balancer-controller?ref=v4.3.0gsa"
  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = data.aws_region.current.name
  k8s_cluster_name = data.aws_eks_cluster.target.name
}
