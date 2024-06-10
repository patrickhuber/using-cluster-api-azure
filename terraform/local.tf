locals {
  admin_ssh_key       = file("~/.ssh/id_rsa.pub")
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "rg-${var.name}-mgmt"
  vnet_name           = "vnet-${var.name}"
}