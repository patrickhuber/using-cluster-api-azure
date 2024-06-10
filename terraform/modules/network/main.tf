# Create virtual network
resource "azurerm_virtual_network" "default" {
  name                = var.name
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
}


# Create subnet
resource "azurerm_subnet" "default" {
  for_each = var.subnet_cidrs

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [each.value]
}
