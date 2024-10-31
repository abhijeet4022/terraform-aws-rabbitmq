# Create SG for RabbitMQ.
resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${local.name_prefix}-sg" })
}


# Ingress rule for RabbitMQ port 5672 from App Subnets.
resource "aws_vpc_security_group_ingress_rule" "allow_rabbitmq" {
  for_each          = toset(var.app_subnets_cidr) # Convert list to a set to iterate over each CIDR
  description       = "Allow inbound TCP on RabbitMQ port 5672 from App Subnets"
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = each.value # Each CIDR block as a separate rule
  from_port         = 5672
  to_port           = 5672
  ip_protocol       = "tcp"
  tags              = { Name = "App-to-RabbitMQ-5672-${each.value}" }
}


# Ingress rule for SSH port 22 from Jumphost EC2.
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  for_each          = toset(var.ssh_subnets_cidr) # Convert list to a set to iterate over each CIDR
  description       = "Allow inbound TCP on RabbitMQ port 5672 from App Subnets"
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = each.value # Each CIDR block as a separate rule
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  tags              = { Name = "Jumphost-to-ssh-22-${each.value}" }
}



# Egress rule for RabbitMQ SG.
resource "aws_vpc_security_group_egress_rule" "main" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Create EC2 for RabbitMQ.
resource "aws_instance" "rabbitmq" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = var.db_subnets[0]
  user_data              = file("${path.module}/userdata.sh")
  tags                   = merge(var.tags, { Name = "${local.name_prefix}" })

  iam_instance_profile = aws_iam_instance_profile.main.name

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = 10
    delete_on_termination = true
    tags                  = merge(var.tags, { Name = "${local.name_prefix}-os-disk" })
  }
}

# Create Route53 record for the rabbitmq.
resource "aws_route53_record" "rabbitmq" {
  zone_id = var.zone_id
  name    = "rabbitmq-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.rabbitmq.private_ip]
}

# New



# Create IAM Policy to provide access SSM Parameter Store.
resource "aws_iam_policy" "main" {
  name        = "${local.name_prefix}-policy"
  path        = "/"
  description = "${local.name_prefix}-policy-to-access-ssm"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : "arn:aws:ssm:us-east-1:060795929502:parameter/payment.${var.env}.*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : "*"
      }
    ]
  })
}


# Create IAM role to allow ec2 to access SSM.
resource "aws_iam_role" "main" {
  name = "${local.name_prefix}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = merge(var.tags, { Name = "${local.name_prefix}-role" })
}


# Attach the Policy with IAM Role.
resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}


# Create IAM instance profile
resource "aws_iam_instance_profile" "main" {
  name = "${local.name_prefix}-role"
  role = aws_iam_role.main.name
}