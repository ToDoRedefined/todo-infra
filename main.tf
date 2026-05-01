resource "azurerm_resource_group" "core" {
  name     = "${local.namespace_prefix}rg-core-${var.environment}-${var.location}"
  location = var.location

  tags = {
    environment : var.environment
  }
}

resource "azurerm_resource_group" "monitoring" {
  name     = "${local.namespace_prefix}rg-monitoring-${var.environment}-${var.location}"
  location = var.location

  tags = {
    environment : var.environment
  }
}
