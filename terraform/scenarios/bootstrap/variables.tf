variable "resource_group_name" {
  type    = string
  default = "clusterapi-bootstrap"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "github_repository" {
  type    = string
  default = "using-cluster-api-azure"
}

variable "github_owner" {
  type = string
}

variable "github_environment" {
  type = string
}

variable "subscription_id" {
  type = string
}
