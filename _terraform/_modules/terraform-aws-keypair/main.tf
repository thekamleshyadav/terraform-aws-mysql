

#Module      : labels
#Description : This terraform module is designed to generate consistent label names and tags
#              for resources. You can use terraform-labels to implement a strict naming
#              convention.
module "labels" {
  source = "../terraform-aws-labels"

  name        = var.name
  environment = var.environment
  label_order = var.label_order
}

#Module      : KEY PAIR
#Description : Terraform module for generating or importing an SSH public key file into AWS.
resource "aws_key_pair" "default" {
  count = var.enable_key_pair == true ? 1 : 0

  key_name   = module.labels.id
  public_key = var.public_key == "" ? file(var.key_path) : var.public_key
  tags       = module.labels.tags
}
