
# resource "aws_eks_cluster" "eks_cluster" {
#   for_each = var.aws_config.eksClusters
#   name     = each.key
#   role_arn = aws_iam_role.role.arn
#   vpc_config {
#     subnet_ids = [for subnetName in each.value["subnets"] : var.aws_subnets[subnetName].id]
#     // To-do use the subnets listed in the config file.
#   }
# }

# resource "aws_eks_node_group" "eks_cluster_nodegroup" {
#   for_each = var.aws_config.eksClusters
#   cluster_name    = aws_eks_cluster.eks_cluster[each.key].name
#   node_group_name = "${each.key}-nodegroup"
#   node_role_arn   = aws_iam_role.role.arn
#   subnet_ids = [for subnetName  in each.value["subnets"] : var.aws_subnets[subnetName].id]

#   scaling_config {
#     desired_size = 3
#     max_size     = 3
#     min_size     = 3
#   }

# }



# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com", "eks.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "role" {
#   name               =replace(replace(replace("config-files/${terraform.workspace}-aws.yaml-terraform-role-eks","/","-"),"\\","-"),".","-")
#  assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# data "aws_iam_policy_document" "policy" {
#   statement {
#     effect    = "Allow"
#     actions   = ["*"]
#     resources = ["*"]
#   }
# }
# resource "aws_iam_policy" "policy" {
# name               =replace(replace(replace("config-files/${terraform.workspace}-aws.yaml-terraform-all-policy","/","-"),"\\","-"),".","-")
#   description = "An open policy for Terraform to use."
#   policy      = data.aws_iam_policy_document.policy.json
# }

# resource "aws_iam_role_policy_attachment" "policy_attachment" {
#   role       = aws_iam_role.role.name
#   policy_arn = aws_iam_policy.policy.arn
# }

resource "aws_eks_cluster" "terraform_eks_cluster" {
  for_each = var.aws_config.eksClusters
  name     = each.key
  role_arn = aws_iam_role.terraform_eks_cluster_role.arn
  version  = each.value["version"] # Specify the Kubernetes version
  vpc_config {
    subnet_ids = [for subnetName in each.value["subnets"] : var.aws_subnets[subnetName].id]
    // To-do use the subnets listed in the config file.
  }
    depends_on = [aws_iam_role.terraform_eks_cluster_role]
  
}

resource "aws_iam_role" "terraform_eks_cluster_role" {
  name = "terraform_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = ["eks.amazonaws.com"]
      }
    }]
  })
}

# resource "aws_iam_role_policy_attachment" "eks_blockstoragepolicy" {
#   role       = aws_iam_role.terraform_eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
# }
resource "aws_iam_role_policy_attachment" "eks_clusterpolicy" {
  role       = aws_iam_role.terraform_eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
# resource "aws_iam_role_policy_attachment" "eks_comnputepolicy" {
#   role       = aws_iam_role.terraform_eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
# }
# resource "aws_iam_role_policy_attachment" "eks_lbpolicy" {
#   role       = aws_iam_role.terraform_eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
# }
# resource "aws_iam_role_policy_attachment" "eks_networkpolicy" {
#   role       = aws_iam_role.terraform_eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
# }


resource "aws_eks_node_group" "terraform_eks_cluster_nodegroup" {
  for_each = var.aws_config.eksClusters
  cluster_name    = aws_eks_cluster.terraform_eks_cluster[each.key].name
  node_group_name = "${each.key}-nodegroup"
  node_role_arn   = aws_iam_role.terraform_eks_ng_role.arn
  subnet_ids = [for subnetName  in each.value["subnets"] : var.aws_subnets[subnetName].id]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

}

resource "aws_iam_role" "terraform_eks_ng_role" {
  name = "terraform_eks_ng_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = ["ec2.amazonaws.com"]
      }
    }]
  })
}

# resource "aws_iam_role_policy_attachment" "ec2_containerregistry_policy" {
#   role       = aws_iam_role.terraform_eks_ng_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
# }

resource "aws_iam_role_policy_attachment" "eks_workernode_policy" {
  role       = aws_iam_role.terraform_eks_ng_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "ec2_containerreadonly_policy" {
  role       = aws_iam_role.terraform_eks_ng_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.terraform_eks_ng_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


# # ECS cluster
# resource "aws_ecs_cluster" "cluster" {
#   name = "example-ecs-cluster"
#   setting {
#     name  = "containerInsights"
#     value = "enabled"
#   }
# }

# # Task definition
# resource "aws_ecs_task_definition" "nginx_task" {
#   family                   = "service"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE", "EC2"]
#   cpu                      = 512
#   memory                   = 2048

#   container_definitions = jsonencode([
#     {
#       name : "nginx",
#       image : "nginx:1.23.1",
#       cpu : 512,
#       memory : 2048,
#       essential : true,
#       portMappings : [
#         {
#           containerPort : 80,
#           hostPort : 80,
#         },
#       ],
#     },
#   ])
# }
# # Service definition
# resource "aws_ecs_service" "service" {
#   name             = "service"
#   cluster          = aws_ecs_cluster.cluster.id
#   task_definition  = aws_ecs_task_definition.nginx_task.arn
#   desired_count    = 3
#   launch_type      = "FARGATE"
#   platform_version = "LATEST"

#   network_configuration {
#     assign_public_ip = true
#     security_groups  = [aws_security_group.ecs_sg.id]
#     subnets          = [aws_subnet.subnets["jump-vpc.subnet-1"].id]
#   }

#   lifecycle {
#     ignore_changes = [task_definition]
#   }
# }

# # Security group for ECS
# resource "aws_security_group" "ecs_sg" {
#   name        = "ecs_security_group"
#   description = "Allow inbound traffic to ECS containers"
#   vpc_id      = aws_vpc.vpcs["jump-vpc"].id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
