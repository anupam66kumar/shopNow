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

  # Automatically gives Jenkins (cluster creator) full cluster admin access
  enable_cluster_creator_admin_permissions = true

  # (Explicit access_entries block removed to avoid the 409 conflict)

  eks_managed_node_groups = {
    spot_nodes = {
      name         = "spot-worker-nodes"
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      # Explicitly set the supported AL2023 AMI for Kubernetes 1.30+
      ami_type = "AL2023_x86_64_STANDARD"

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
