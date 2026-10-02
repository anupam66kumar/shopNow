data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # Gives current user / cluster creator admin rights
  enable_cluster_creator_admin_permissions = true

  # Map Jenkins EC2 IAM Role to Cluster Admin
  access_entries = {
    jenkins_admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Jenkins-Capstone-Role"
      policy_associations = {
        admin_policy = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  eks_managed_node_groups = {
    spot_nodes = {
      name         = "spot-worker-nodes"
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT" # Cost optimization

      subnet_ids = module.vpc.private_subnets

      labels = {
        Environment = "capstone"
        NodeType    = "spot"
      }
    }
  }

  tags = {
    Environment = "capstone"
    Project     = "ShopNow"
  }
}
