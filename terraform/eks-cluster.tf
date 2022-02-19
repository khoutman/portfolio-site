module "kyle-oakley-eks-cluster" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 15.1.0"

  create_eks = true
  cluster_name = local.cluster_name
  cluster_version = "1.21"
  vpc_id = data.aws_vpc.application-vpc.id
  subnets = [
    data.aws_subnet.kubernetes-public-subnet.id,
    data.aws_subnet.kubernetes-test-public-subnet.id
  ]

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      instance_type = "t3.medium"
      asg_max_size = 3
      asg_desired_capacity = 2
      asg_min_size = 2
      kubelet_extra_args = "--node-labels=workload=production-applications"
    },
    {
      instance_type = "t3.medium"
      asg_max_size = 1
      asg_desired_capacity = 1
      asg_min_size = 1
      kubelet_extra_args = "--node-labels=workload=development-tests"
    }
  ]
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list = ["sts.amazonaws.com"]
  // Thumbprint for us-east-1: https://github.com/terraform-providers/terraform-provider-aws/issues/10104#issuecomment-633130751
  // OIDC Thumbprint: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  // https://marcincuber.medium.com/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "alb-ingress-controller-policy-document" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    condition {
      test = "StringEquals"
      values = ["system:serviceaccount:kube-system:aws-alb-ingress-controller"]
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type = "Federated"
    }
  }
}

resource "aws_iam_role" "alb-ingress-controller-role" {
  name = "aws-alb-ingress-controller"
  path = "/kubernetes/"
  assume_role_policy = data.aws_iam_policy_document.alb-ingress-controller-policy-document.json
}

resource "aws_iam_policy" "alb-ingress-controller-policy" {
  name = "aws-alb-ingress-controller"
  path = "/kubernetes/"
  policy = file("${path.module}/alb-ingress-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb-ingress-controller-role-policy" {
  policy_arn = aws_iam_policy.alb-ingress-controller-policy.arn
  role = aws_iam_role.alb-ingress-controller-role.name
}

resource "aws_iam_policy" "external-dns-policy" {
  name = "external-dns"
  path = "/kubernetes/"
  policy = file("${path.module}/external-dns-policy.json")
}

resource "aws_iam_role_policy_attachment" "external-dns-role-policy" {
  policy_arn = aws_iam_policy.external-dns-policy.arn
  role = module.kyle-oakley-eks-cluster.worker_iam_role_name
}

resource "aws_iam_policy" "worker-pods-policy" {
  name = "worker-pods"
  path = "/kubernetes/"
  policy = file("${path.module}/worker-pods-policy.json")
}

resource "aws_iam_role_policy_attachment" "worker-pods-role-policy" {
  policy_arn = aws_iam_policy.worker-pods-policy.arn
  role = module.kyle-oakley-eks-cluster.worker_iam_role_name
}

resource "aws_security_group_rule" "cluster-nodes-alb-security-group-rule" {
  type = "ingress"
  from_port = 30000
  to_port = 32767
  protocol = "TCP"
  cidr_blocks = ["10.0.0.0/8"]
  security_group_id = module.kyle-oakley-eks-cluster.worker_security_group_id
  description = "Inbound access to worker nodes from ALBs created by an EKS ingress controller."
}

resource "aws_security_group_rule" "rds-outbound-security-group-rule" {
  type = "egress"
  from_port = 3306
  to_port = 3306
  protocol = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.kyle-oakley-eks-cluster.worker_security_group_id
  description = "Outbound access to RDS instances from the worker nodes."
}

resource "aws_security_group_rule" "rds-inbound-security-group-rule" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.kyle-oakley-eks-cluster.worker_security_group_id
  description = "Inbound access from RDS instances to the worker nodes."
}
