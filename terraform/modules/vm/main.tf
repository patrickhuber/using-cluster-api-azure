# Create public IPs
resource "azurerm_public_ip" "default" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.name}PublicIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "default" {
  name                = "${var.name}Nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.name}NicCfg"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip ? azurerm_public_ip.default.0.id : null
  }
}

# Create the network security group relationship
resource "azurerm_network_interface_security_group_association" "nsg" {
  count                     = var.nsg.enabled ? 1 : 0
  network_interface_id      = azurerm_network_interface.default.id
  network_security_group_id = var.nsg.enabled ? var.nsg.id : null
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "default" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.size

  network_interface_ids = [azurerm_network_interface.default.id]

  os_disk {
    name                 = "${var.name}OSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = var.name
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = var.admin_ssh_key
  }
}