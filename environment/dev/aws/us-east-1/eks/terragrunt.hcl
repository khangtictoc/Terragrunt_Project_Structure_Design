include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}



# Use self-developed modules
# terraform {
#     source = "../../../../../modules/aws/vpc"
# }

# ┌──────────────────────────────────────┐
# │                                      │
# │    Use Official  Community Module    │
# │                                      │
# └──────────────────────────────────────┘

terraform {
  source  = "tfr:///terraform-aws-modules/eks/aws?version=21.0.6"
}

locals {
  name = "testproject-${local.env}"
  vpc_cidr = "10.0.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  env    = include.root.locals.env
  tags   = include.root.locals.tags
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  name               = local.name
  kubernetes_version = "1.33"

  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = [for subnet_id in dependency.vpc.outputs.private_subnets : subnet_id]

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  eks_managed_node_groups  = {
    oss = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 1
      max_size     = 2
      desired_size = 2
    }
  }

  tags   = local.tags
}

