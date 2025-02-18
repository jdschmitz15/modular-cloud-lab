output "aws_eks_clusters" {
  value = { for k, v in aws_eks_cluster.terraform_eks_cluster : k => v.name }
}