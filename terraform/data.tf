data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.kyle-oakley-eks-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.kyle-oakley-eks-cluster.cluster_id
}

data "aws_vpc" "application-vpc" {
  tags = {
    Name = "application-vpc"
  }
}

data "aws_subnet" "kubernetes-test-dotty-public-subnet" {
  tags = {
    Name = "kubernetes-test-public-subnet"
  }
}

data "aws_subnet" "kubernetes-public-subnet" {
  tags = {
    Name = "kubernetes-public-subnet"
  }
}

data "tls_certificate" "cluster" {
  url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}
