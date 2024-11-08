data azurerm_subscription current{}

resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.location
}

data "github_actions_public_key" "public_key" {
  repository = var.github_repository
}

resource "github_actions_secret" "client_id" {
  repository      = var.github_repository
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = module.github_federated_identity.client_id
}

resource "github_actions_secret" "subscription_id" {
  repository      = var.github_repository
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = module.github_federated_identity.subscription_id
}

resource "github_actions_secret" "tenant_id" {
  repository      = var.github_repository
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = module.github_federated_identity.tenant_id
}

module "github_federated_identity" {
  source = "../../modules/federated-identity"

  location = var.location
  resource_group_name = var.resource_group_name

  name = "using-cluster-api-github-pipeline"
  description = ""

  subject = [ 
    "repo", "${var.github_owner}/${var.github_repository}", 
    "environment", var.github_environment
  ]

  roles = [ 
    {
    role = "Contributor"
    scope = data.azurerm_subscription.current.id
    } 
  ]
}

module "state_store" {
  source = "../../modules/storage-account"
  resource_group_name = azurerm_resource_group.default.name
  location = var.location 
  name = "state" 
}