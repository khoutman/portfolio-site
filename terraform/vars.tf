variable "alb_controller_depends_on" {
  description = "Resources that the module should wait for before starting the controller. For example if there is no node_group, 'aws_eks_fargate_profile.default'"
}
