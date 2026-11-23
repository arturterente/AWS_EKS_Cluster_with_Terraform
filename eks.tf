terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
  provider "aws" {
    region = "eu-central-1"
  }

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Public"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Public2"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_eks_node_group" "worker-nodes" {
  cluster_name    = "my-eks-cluster"
  node_group_name = "worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [
      aws_subnet.public_subnet2.id,
      aws_subnet.public_subnet.id
    ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_read,
  ]
}

resource "aws_eks_cluster" "kube-ec2" {
  name = "my-eks-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster-role.arn
  version  = "1.35"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet2.id,
      aws_subnet.public_subnet.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

#
# NOW CREATE IAM ROLES FOR EKS CLUSTER AND FOR NODES (BUCKET WHERE POLICIES ARE STORED)
#

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { 
        Service = "ec2.amazonaws.com"
       }
      Action    = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role" "cluster-role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

#
# ATTACH POLICIES TO ROLES
#

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}




#log into aws ($ aws configure)
#run aws eks update-kubeconfig --name my-eks-cluster --region eu-central-1
# add access to EKS using my arn ($ aws sts get-caller-identity) in IAM console
# add policy AmazonEKSClusterPolicy in IAM → Users → arturterente -> add permission -> attach policies directly
