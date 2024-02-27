################
# Regions
################
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "AWS Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

################
# EKS
################
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "eks-lab"
}

variable "cluster_version" {
  description = "EKS Cluster Version"
  type        = string
  default     = "1.29"
}

##################
# EKS Node Group
##################
variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "node-group-1"
}

# Refer:
#   - Spot: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html
#   - On-demand: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-on-demand-instances.html
variable "capacity_type" {
  description = "Capacity type"
  type        = string
  default     = "ON_DEMAND"
}

variable "instance_types" {
  description = "Instance types by configurations"
  type        = list(string)
  default     = ["t3.small"]
}

#####################
# NGINX Deployment
#####################
variable "web_server" {
  description = "Name for web server deployment"
  type        = string
  default     = "nginx"
}

variable "web_server_img" {
  description = "Image for web server deployment"
  type        = string
  default     = "nginx:1.25.0"
}


################
# Networking
################

# CIDR(s)
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_cidr_blocks" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.33.0/24"]
}

variable "public_cidr_blocks" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.22.0/24"]
}

# IGW (Internet Gateways)

variable "igw_tags" {
  description = "Tags for internet gateways"
  type        = map(string)
  default = {
    Name = "igw-eks-nginx-lab"
  }
}

# Route Table

variable "private_rt_tags" {
  description = "Tags for private route tables"
  type        = map(string)
  default = {
    Name = "private-rt"
  }
}

variable "public_rt_tags" {
  description = "Tags for public route tables"
  type        = map(string)
  default = {
    Name = "public-rt"
  }
}

# EIP

variable "eip_tags" {
  description = "Tags for Elastic IP"
  type        = map(string)
  default = {
    Name = "eks-eip"
  }
}

# NAT Gateway

variable "nat_gw_tags" {
  description = "Tags for NAT Gateway"
  type        = map(string)
  default = {
    Name = "eks-nat-gw"
  }
}

################
# Tags
################
variable "eks_resource_general_tags" {
  description = "General tags for resources on this EKS cluster"
  type        = map(string)
  default = {
    "Name" = "eks-nginx-lab"
  }
}

variable "private_lb_tags" {
  description = "Tags for private subnets"
  type        = map(string)
  default = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-lab"   = "owned"
  }
}

variable "public_lb_tags" {
  description = "Tags for public subnets"
  type        = map(string)
  default = {
    "kubernetes.io/role/elb"        = "1"
    "kubernetes.io/cluster/eks-lab" = "owned"
  }
}
