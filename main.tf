resource "azurerm_resource_group" "core" {
  name     = "${namespace_prefix}rg-core-${var.environment}-${var.location}"
  location = var.location

  tags = {
    environment : var.environment
  }
}
