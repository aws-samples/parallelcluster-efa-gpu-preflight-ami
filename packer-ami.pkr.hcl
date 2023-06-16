packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.9"
      source = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.0.1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

variable "ami_name" {
  type    = string
  default = "pcluster-gpu-efa"
}

variable "ami_version" {
  type    = string
  default = "1.0.0"
}

variable "parallel_cluster_version" {
  type    = string
  default = "3.3.0"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "g4dn.12xlarge"
}

variable "inventory_directory" {
  type    = string
  default = "inventory"
}

variable "playbook_file" {
  type    = string
  default = "packer-playbook.yml"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "aws-pcluster-ami" {
  ami_name      = "${var.ami_name}-${var.ami_version}-${local.timestamp}"
  instance_type = "${var.instance_type}"
  region        = "${var.aws_region}"
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name = "aws-parallelcluster-${var.parallel_cluster_version}-amzn2-*"
      architecture= "x86_64"
      root-device-type = "ebs"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username  = "ec2-user"
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 100 
    throughput            = 1000
    iops                  = 10000
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = {
    "OS" =  "Amazon Linux 2",
    "parallelcluster:version" =  "${var.parallel_cluster_version}"
    "parallelcluster:build_status" = "available"
    "parallelcluster:os" = "alinux2"
  }
}

build {
  sources = ["source.amazon-ebs.aws-pcluster-ami"]

  provisioner "shell" {
    inline = ["sudo yum remove -y dpkg",
              "sudo yum install -y python3-pip",
              "sudo python3 -m pip install ansible"]
  }
  provisioner "ansible-local" {
    playbook_file   = "${var.playbook_file}"
    role_paths      = ["./roles/base",
                       "./roles/packages",
                       "./roles/aws_cliv2",
                       "./roles/docker",
                       "./roles/aws_efa",
                       "./roles/nvidia_driver",
                       "./roles/nvidia_docker",
                       "./roles/nvidia_cuda",
                       "./roles/nvidia_gdrcopy",
                       "./roles/nvidia_nccl",
                       "./roles/nvidia_enroot_pyxis",
                       "./roles/aws_efa_ofi",
                       "./roles/aws_lustre",
                       "./roles/observability"]
  }
}
