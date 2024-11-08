data azurerm_subscription current{  
}

resource azurerm_user_assigned_identity default {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
}

resource azurerm_role_assignment assignment{
  count = length(var.roles)

  scope = var.roles[count.index].scope
  role_definition_name = var.roles[count.index].role
  principal_id = azurerm_user_assigned_identity.default.principal_id
}

resource "azurerm_federated_identity_credential" default {
    name = var.name
    resource_group_name = var.resource_group_name
    audience =  var.audiences
    issuer = var.issuer
    parent_id = azurerm_user_assigned_identity.default.id
    subject = join(":", var.subject)
}
