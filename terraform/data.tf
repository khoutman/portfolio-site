data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.kyle-oakley-eks-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.kyle-oakley-eks-cluster.cluster_id
}

data "tls_certificate" "cluster" {
  url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}
