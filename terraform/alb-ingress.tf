module "alb_controller" {
  source  = "iplabs/alb-controller/kubernetes"
  version = "3.4.0"

  providers = {
    kubernetes = "kubernetes.eks",
    helm       = "helm.eks"
  }

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = data.aws_region.current.name
  k8s_cluster_name = data.aws_eks_cluster.target.name
}
