variable "resource_group_name" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "username" {
  type      = string
  sensitive = true
}

variable "name" {
  type    = string
  default = "foundation"
}

variable "cluster_node_size" {
  type    = string
  default = "Standard_B2s"
}

variable "jumpbox_node_size" {
  type    = string
  default = "Standard_B2s"
}