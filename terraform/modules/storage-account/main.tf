# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  byte_length = 8
}

# create storage account
resource "azurerm_storage_account" "account" {
  name                     = "sa${random_id.random_id.hex}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
}

resource "azurerm_storage_container" "container"{
  count = length(var.containers)
  storage_account_name = azurerm_storage_account.account.name
  name = var.containers[count.index].name
  container_access_type = var.containers[count.index].access_type
}