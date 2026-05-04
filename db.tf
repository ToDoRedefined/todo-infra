resource "azurerm_resource_group" "db" {
  name     = "${local.namespace_prefix}rg-db-${var.environment}-${var.location}"
  location = var.location

  tags = local.tags
}

# Genereate a random password for the PostgreSQL server administrator
resource "random_password" "postgres_admin_password" {
  length  = 16
  special = true
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "todo-postgres-${var.environment}-${var.location}"
  resource_group_name    = azurerm_resource_group.db.name
  location               = azurerm_resource_group.db.location
  version                = "12"
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgres_admin_password.result
  zone                   = "1"
  storage_mb             = 32768
  storage_tier           = "P4"
  sku_name               = "B_Standard_B1ms"

  tags = local.tags
}

resource "azurerm_postgresql_flexible_server_database" "postgres_db" {
  name      = "tasks"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Allow access to the PostgreSQL server from Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Save the PostgreSQL admin password in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "DB-PASSWORD"
  value        = random_password.postgres_admin_password.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "db_host" {
  name         = "DB-HOST"
  value        = azurerm_postgresql_flexible_server.postgres.fqdn
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}


resource "azurerm_key_vault_secret" "db_user" {
  name         = "DB-USER"
  value        = azurerm_postgresql_flexible_server.postgres.administrator_login
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}


resource "azurerm_key_vault_secret" "db_port" {
  name         = "DB-PORT"
  value        = "5432"
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "todo-cosmos-${var.environment}-${var.location}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name

  offer_type = "Standard"
  kind       = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.core.location
    failover_priority = 0
  }

  tags = local.tags
}

resource "azurerm_cosmosdb_sql_database" "cosmos_db" {
  name                = "todo-audit"
  resource_group_name = azurerm_resource_group.core.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "cosmos_container" {
  name                  = "events"
  resource_group_name   = azurerm_resource_group.core.name
  account_name          = azurerm_cosmosdb_account.cosmos.name
  database_name         = azurerm_cosmosdb_sql_database.cosmos_db.name
  partition_key_paths   = ["/id"]
  partition_key_version = 1
}

resource "azurerm_key_vault_secret" "cosmos_endpoint" {
  name         = "COSMOS-ENDPOINT"
  value        = azurerm_cosmosdb_account.cosmos.endpoint
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "cosmos_key" {
  name         = "COSMOS-KEY"
  value        = azurerm_cosmosdb_account.cosmos.primary_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "cosmos_db" {
  name         = "COSMOS-DATABASE"
  value        = azurerm_cosmosdb_sql_database.cosmos_db.name
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "cosmos_container" {
  name         = "COSMOS-CONTAINER"
  value        = azurerm_cosmosdb_sql_container.cosmos_container.name
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_redis_cache" "redis" {
  name                = "todo-redis-${var.environment}-${var.location}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name

  capacity = 1
  family   = "C"
  sku_name = "Basic" # use Standard/Premium in prod

  non_ssl_port_enabled = false

  redis_configuration {}

  tags = local.tags
}

resource "azurerm_key_vault_secret" "redis_host" {
  name         = "REDIS-HOST"
  value        = azurerm_redis_cache.redis.hostname
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "redis_port" {
  name         = "REDIS-PORT"
  value        = tostring(azurerm_redis_cache.redis.ssl_port)
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "redis_password" {
  name         = "REDIS-PASSWORD"
  value        = azurerm_redis_cache.redis.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}
