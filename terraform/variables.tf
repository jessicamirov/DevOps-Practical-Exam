variable "region" {
  description = "my AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "my default VPC ID"
  type        = string
  default     = "vpc-044604d0bfb707142"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "builder"
}

variable "instance_type" {
  description = "Type of the EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "UBUNTU AMI ID"
  type        = string
  default     = "ami-084568db4383264d4" 
}

variable "subnet_id" {
  description = "subnet ID from vpc"
  type        = string
  default     = "subnet-05e39308bb4a1d087"
}

variable "ssh_port" {
  description = "The port to use for SSH access"
  type        = number
  default     = 22
}

variable "jenkins_port" {
  description = "The port to use for Jenkins"
  type        = number
  default     = 8080
}

variable "python_app_port" {
  description = "The port to use for the Python application"
  type        = number
  default     = 5001
}

variable "myname" {
  description = "use my name"
  type        = string
  default     = "jessica"
}