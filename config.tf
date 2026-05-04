resource "azurerm_resource_group" "config" {
  name     = "${local.namespace_prefix}rg-config-${var.environment}-${var.location}"
  location = var.location

  tags = local.tags
}


resource "azurerm_app_configuration" "appconf" {
  name                = "appconf-${var.environment}-${var.location}"
  resource_group_name = azurerm_resource_group.config.name
  location            = azurerm_resource_group.config.location

  tags = local.tags
}

resource "azurerm_role_assignment" "appconf_dataowner" {
  scope                = azurerm_app_configuration.appconf.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_app_configuration_key" "appconf_key" {
  for_each = {
    for item in flatten([
      for label, kvs in local.app_configuration_keys : [
        for k, v in kvs : {
          label = label
          key   = k
          value = v
        }
      ]
    ]) :
    "${item.label}-${item.key}" => item
  }
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = each.value.key
  label                  = each.value.label
  value                  = each.value.value

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}
