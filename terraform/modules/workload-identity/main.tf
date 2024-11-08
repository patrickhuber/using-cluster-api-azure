
resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.location
}

module "storage-account" {
  source              = "../storage-account"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  containers = [ 
    { 
      name = local.storage_container_name
      access_type = "blob"
    }
  ]
}

resource "azurerm_storage_blob" "openid_configuration"{
  name = "openid-configuration.json"
  storage_container_name = local.storage_container_name
  storage_account_name = module.storage_account.storage_account_name
  type = "Block"
  content_type = "application/json"
  source_content = jsonencode({
    issuer = "https://${module.storage_account.storage_account_name}}.blob.core.windows.net/${local.storage_container_name}/"
    jwks_uri = "https://${module.storage_account.storage_account_name}.blob.core.windows.net/${local.storage_container_name}/openid/v1/jwks",
    response_types_supported = [
      "id_token"
    ]
    subject_types_supported = [
      "public"
    ]
    id_token_signing_alg_values_supported = [
      "RS256"
    ]
  })
  depends_on = [ module.storage_account ]
}