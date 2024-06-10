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

# Create Network Security Group and rule
resource "azurerm_network_security_group" "jumpbox" {
  name                = "nsgJumpbox"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

module "jumpbox" {
  source = "./modules/vm"

  name = "jumpbox"

  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  size = var.jumpbox_node_size

  subnet_id = module.network.subnet_ids[0]
  nsg    = { 
    id = azurerm_network_security_group.jumpbox.id 
    enabled = true
  }
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