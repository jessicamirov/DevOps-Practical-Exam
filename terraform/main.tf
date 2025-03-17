provider "aws" {
  region = var.region
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.myname}-builder-key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "builder_key" {
  key_name   = "${var.myname}-builder-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

data "aws_vpc" "my_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

resource "aws_security_group" "builder_sg" {
  name        = "${var.myname}-builder-sg"
  description = "Security group for builder instance"
  vpc_id      = data.aws_vpc.my_vpc.id

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = var.python_app_port
    to_port     = var.python_app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Python application access"
  }

  ingress {
    from_port   = var.jenkins_port
    to_port     = var.jenkins_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.myname}-sg"
  }
}

resource "aws_instance" "builder" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.builder_key.key_name
  vpc_security_group_ids = [aws_security_group.builder_sg.id]
  subnet_id              = var.subnet_id 

  tags = {
    Name = "${var.myname}-${var.instance_name}"
  }

  # Install Docker and Docker Compose
  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    apt-get update
    apt-get upgrade -y

    # Install required packages
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    # Add Docker repository
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Add ubuntu user to the docker group
    usermod -aG docker ubuntu
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}