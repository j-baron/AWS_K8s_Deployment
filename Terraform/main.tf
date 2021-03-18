provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "kubernetes_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "kubernetes"
  vpc_id      = module.vpc.vpc_id
  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ec2_cluster" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "my-cluster"
  instance_count         = 3

  ami                    = "${data.aws_ami.ubuntu-xenial.id}"
  instance_type          = "t2.micro"
  key_name               = "key_name"
  monitoring             = true
  vpc_security_group_ids = [module.kubernetes_sg.this_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data = "adduser --quiet --disabled-password --shell /bin/bash --home /home/ansible --gecos 'User' ansible; echo 'ansible:ansible' | chpasswd"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_ami" "ubuntu-xenial" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  owners      = ["099720109477"]
}

output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = module.ec2_cluster.public_ip
}

resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
    {
        instance_one = module.ec2_cluster.public_ip[0],
        instance_two = module.ec2_cluster.public_ip[1],
        instance_three = module.ec2_cluster.public_ip[2]
    }
    )
    filename = "inventory"
}