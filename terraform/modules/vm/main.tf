# Create public IPs
resource "azurerm_public_ip" "default" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.name}PublicIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
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
  }
}

# Create Network Security Group
resource "azurerm_network_security_group" "default" {
  name                = "${var.name}Nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Create a load balancer
resource "azurerm_lb" "default" {
  count = var.public_ip ? 1 : 0

  name                = "${var.name}LB"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.default.0.id
  }
}

# Create a backend pool for the load balancer
resource "azurerm_lb_backend_address_pool" "default" {
  count           = var.public_ip ? 1 : 0
  loadbalancer_id = azurerm_lb.default.0.id
  name            = "pool"
}

# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "default" {
  count = var.public_ip ? 1 : 0

  network_interface_id    = azurerm_network_interface.default.id
  ip_configuration_name   = azurerm_network_interface.default.ip_configuration.0.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.default.0.id
}

# Create a nat pool to translate port 8022 to 22
resource "azurerm_lb_nat_rule" "default" {
  count = var.public_ip ? 1 : 0

  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.default.0.id
  name                           = "SSH"
  protocol                       = "Tcp"  
  frontend_port                  = 222
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.default.0.frontend_ip_configuration.0.name
  
}

# Create the network security group relationship
resource "azurerm_network_interface_security_group_association" "nsg" {  
  network_interface_id      = azurerm_network_interface.default.id
  network_security_group_id = azurerm_network_security_group.default.id
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