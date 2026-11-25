# AWS EKS Cluster with Terraform

This repository contains Terraform configuration to provision an Amazon EKS cluster with a managed EC2 node group inside a custom VPC

## Architecture Overview

- **VPC (`10.0.0.0/16`)**: Custom VPC with an Internet Gateway and public route table.
- **Subnets**: Two public subnets across separate Availability Zones (`10.0.1.0/24` and `10.0.2.0/24`) with auto-assign public IP enabled (`map_public_ip_on_launch = true`).
- **EKS Cluster**: Kubernetes `1.35` configured with `API` authentication mode.
- **Managed Node Group**: Auto-scaling EC2 worker nodes (`desired = 2`, `min = 1`, `max = 3`) using `t2.micro` instances.
- **IAM Roles & Policies**:
  - Cluster Role (`eks-cluster-role`) with `AmazonEKSClusterPolicy`
  - Node Group Role (`eks-node-group-role`) with `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, and `AmazonEC2ContainerRegistryReadOnly`

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (`>= 1.0`)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with valid credentials (`aws configure`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed

---

## Usage

### 1. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
