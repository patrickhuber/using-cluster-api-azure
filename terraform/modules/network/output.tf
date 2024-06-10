output "virtual_network_id" {
  value       = azurerm_virtual_network.default.id
  description = "the virtual network id"
}

output "subnet_ids" {
  value       = values(azurerm_subnet.default)[*].id
  description = "the virtual network subnet ids"
}