variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "size" {
  type = string
}

variable "username" {
  type      = string
  sensitive = true
}

variable "admin_ssh_key" {
  type      = string
  sensitive = true
}

variable "subnet_id" {
  type = string
}

variable "public_ip" {
  type    = bool
  default = false
}