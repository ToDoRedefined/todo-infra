resource "azurerm_resource_group" "core" {
  name = "${var.namespace}rg-core-${var.environment}-${var.location}"
  location = var.location
}