output "subscription_id" {
    value = data.azurerm_subscription.current.subscription_id
}

output "tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
}

output "client_id" {
  value = azurerm_user_assigned_identity.default.client_id
}