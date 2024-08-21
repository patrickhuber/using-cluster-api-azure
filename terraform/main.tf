resource "azurerm_resource_group" "management" {
  name     = local.resource_group_name
  location = var.location
}

module "network" {
  source = "./modules/network"

  name = local.vnet_name

  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  vnet_cidr = "10.0.0.0/16"

  subnet_cidrs = {
    management = "10.0.0.0/24"
  }

  depends_on = [azurerm_resource_group.management]
}

module "jumpbox" {
  source = "./modules/vm"

  name = "jumpbox"

  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  size = var.jumpbox_node_size

  subnet_id = module.network.subnet_ids[0]
  public_ip = true

  username      = var.username
  admin_ssh_key = local.admin_ssh_key

  depends_on = [module.network]
}

module "cluster" {
  source = "./modules/vm"

  name = "cluster"

  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  size = var.cluster_node_size

  subnet_id = module.network.subnet_ids[0]

  username      = var.username
  admin_ssh_key = local.admin_ssh_key

  depends_on = [module.network]
}