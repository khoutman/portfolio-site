locals {
  public_cidr = "0.0.0.0/0"
  cluster_name = "kyle-oakley-eks-cluster"

  kubernetes_public_subnet_cidrs = [
    "10.1.1.0/24",
    "10.1.2.0/24"
  ]

  kubernetes_private_subnet_cidrs = [
    "10.1.3.0/24",
    "10.1.4.0/24"
  ]

  kubernetes_vpc_sg_rules = [
    {
      # Inbound traffic from the internet
      type = "ingress"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = local.public_cidr
    },
    {
      type = "ingress"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = local.public_cidr
    },
    {
      type = "ingress"
      from_port = -1
      to_port = -1
      protocol = "icmp"
      cidr_blocks = local.public_cidr
    },
    {
      type = "ingress"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = local.public_cidr
    },
    {
      # Outbound traffic for health checks
      type = "egress"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = local.public_cidr
    },
    {
      # Outbound traffic for HTTP
      type = "egress"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = local.public_cidr
    },
    {
      # Outbound traffic for HTTPS
      type = "egress"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = local.public_cidr
    },
  ]

  kubernetes_public_subnet_azs = [
    "us-east-1a",
    "us-east-1b"
  ]

  kubernetes_private_subnet_azs = [
    "us-east-1b",
    "us-east-1c"
  ]

  subnet_tags = {
    Application = "kubernetes",
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/elb" = "1"
  }

  kubernetes_public_subnet_tags = [local.subnet_tags, local.subnet_tags]
  kubernetes_private_subnet_tags = [local.subnet_tags, local.subnet_tags]
}
