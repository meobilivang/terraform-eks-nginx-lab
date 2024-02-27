output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.eks-lab.endpoint
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.eks-lab.id
}

output "cluster_version" {
  description = "EKS Version"
  value       = aws_eks_cluster.eks-lab.version
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks-lab.certificate_authority[0].data
}
