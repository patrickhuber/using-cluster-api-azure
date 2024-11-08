terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.8.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.3.1"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  # Configuration options
  features {}
}

provider "github" {
  # Configuration options
  owner = var.github_owner
}