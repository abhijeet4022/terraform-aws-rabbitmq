variable "tags" {}
variable "env" {}

# SG Variables
variable "vpc_id" {
  description = "ID of the Main VPC"
}

variable "app_subnets_cidr" {
  description = "CIDR blocks for application subnets"
}

variable "ssh_subnets_cidr" {
  description = "CIDR blocks for SSH access subnets/server"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  description = "EC2 instance type for RabbitMQ"
}

variable "db_subnets" {
  description = "Database subnets for RabbitMQ"
}

variable "zone_id" {
  description = "Route53 hosted zone ID for the domain"
}

variable "kms_key_id" {
  description = "Provide the KMS ARN"
}