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
  default = "3.5.0"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_subnet" {
  type    = string
  default = "subnet-a2b278fd"
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
  subnet_id     = "${var.aws_subnet}"
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name = "aws-parallelcluster-${var.parallel_cluster_version}-amzn2-hvm-*"
      architecture= "x86_64"
      root-device-type = "ebs"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username  = "ec2-user"
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_type           = "gp3"
    delete_on_termination = true

    # Frugal setting: smaller AMI, iops, and throughput, but longer build time.
    # Note that volume_size >= size_of(base_ami).
    # [20230309] Space usage: CPU-AMI=17GB, GPU-AMI=25GB.
    #volume_size           = 35
    #throughput            = 125
    #iops                  = 3000

    volume_size           = 100
    throughput            = 1000
    iops                  = 10000
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

  provisioner "ansible" {
    user                = "ec2-user"
    inventory_directory = "${var.inventory_directory}"
    playbook_file       = "${var.playbook_file}"

    # https://github.com/hashicorp/packer-plugin-ansible/issues/69#issuecomment-1342585096
    #ansible_ssh_extra_args  = ["-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa -o IdentitiesOnly=yes -oServerAliveInterval=60 -oServerAliveCountMax=120 -oTCPKeepAlive=yes"]
    ansible_ssh_extra_args  = ["-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa -o IdentitiesOnly=yes"]
    extra_arguments         = [ "--scp-extra-args", "'-O'" ]
  }
}
