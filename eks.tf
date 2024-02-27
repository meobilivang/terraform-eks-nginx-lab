##################
# EKS
##################

# Refer: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/main.tf#L27
resource "aws_eks_cluster" "eks-lab" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-lab-iam-role.arn

  depends_on = [aws_iam_role_policy_attachment.eks-lab-AmazonEKSClusterPolicy]

  vpc_config {
    subnet_ids = [
      aws_subnet.us-east-1a-private.id,
      aws_subnet.us-east-1b-private.id,
      aws_subnet.us-east-1a-public.id,
      aws_subnet.us-east-1b-public.id
    ]
  }
}

##################
# IAM for EKS
##################

# Refer:
# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/main.tf#L362-L394
data "aws_iam_policy_document" "eks-assume-role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks-lab-iam-role" {
  name               = "eks-lab-iam-role"
  assume_role_policy = data.aws_iam_policy_document.eks-assume-role.json
}

# Permission for EKS to manage resources
resource "aws_iam_role_policy_attachment" "eks-lab-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-lab-iam-role.name
}

##############################
# EKS Node Group
##############################

# Node group
# Refer: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group#example-usage
resource "aws_eks_node_group" "node-group-1" {

  # cluster info
  cluster_name = aws_eks_cluster.eks-lab.name
  version      = var.cluster_version

  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks-nodes-iam-role.arn
  subnet_ids = [
    aws_subnet.us-east-1a-private.id,
    aws_subnet.us-east-1b-private.id
  ]

  scaling_config {
    desired_size = 3
    max_size     = 6
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-nodes-AmazonEC2ContainerRegistryReadOnly,
  ]

  # Configuration for Instance(s)
  capacity_type  = var.capacity_type
  instance_types = var.instance_types
}

##############################
# IAM for Managed Node group
##############################

data "aws_iam_policy_document" "eks-nodes-assume-role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks-nodes-iam-role" {
  name               = "eks-nodes-iam-role"
  assume_role_policy = data.aws_iam_policy_document.eks-nodes-assume-role.json
}

# Refer:
#   - https://docs.aws.amazon.com/eks/latest/userguide/eks-networking-add-ons.html
#   - https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKS_CNI_Policy.html
# Granting permission for EKS CNI plugin (`Amazon VPC CNI` is built-in on EKS)
resource "aws_iam_role_policy_attachment" "eks-nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-nodes-iam-role.name
}

# Refer: https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKSWorkerNodePolicy.html
# Allowing EKS worker nodes to connect to EKS Cluster
resource "aws_iam_role_policy_attachment" "eks-nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-nodes-iam-role.name
}

resource "aws_iam_role_policy_attachment" "eks-nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-nodes-iam-role.name
}


