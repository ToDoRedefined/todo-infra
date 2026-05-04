resource "azurerm_resource_group" "compute" {
  name     = "${local.namespace_prefix}rg-compute-${var.environment}-${var.location}"
  location = var.location

  tags = local.tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.environment}-${var.location}"
  location            = azurerm_resource_group.compute.location
  resource_group_name = azurerm_resource_group.compute.name
  dns_prefix          = "aks-${var.environment}-${var.location}"

  kubernetes_version = "1.35.0"

  default_node_pool {
    name       = "systempool"
    node_count = 1
    vm_size    = "standard_d2ls_v5"

    vnet_subnet_id = azurerm_subnet.snet["aks"].id

    # 👇 Critical for system pool
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  role_based_access_control_enabled = true

  tags = local.tags
}


resource "azurerm_kubernetes_cluster_node_pool" "app_pool" {
  name                  = "apppool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id

  vm_size    = "standard_d2ls_v5"
  node_count = 1

  mode = "User"

  vnet_subnet_id = azurerm_subnet.snet["aks"].id

  orchestrator_version = azurerm_kubernetes_cluster.aks.kubernetes_version

  tags = local.tags
}
