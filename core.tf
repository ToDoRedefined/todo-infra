resource "azurerm_resource_group" "core" {
  name     = "${local.namespace_prefix}rg-core-${var.environment}-${var.location}"
  location = var.location

  tags = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}-${var.location}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  address_space       = ["10.60.0.0/16"]

  tags = local.tags
}

resource "azurerm_subnet" "snet" {
  for_each             = local.subnets
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.environment}-${var.location}"
  location                   = azurerm_resource_group.core.location
  resource_group_name        = azurerm_resource_group.core.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
