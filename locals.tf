locals {
  tags        = merge(var.tags, { module-name = "rabbitmq" }, { env = var.env })
  name_prefix = "${var.env}-rabbitmq"
}

