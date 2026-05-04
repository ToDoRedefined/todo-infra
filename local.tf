locals {
  namespace_prefix = var.environment == "eph" && trimspace(var.namespace) != "" ? "${var.namespace}-" : var.namespace

  tags = {
    environment : var.environment
  }

  subnets = {
    "aks" = {
      name           = "snet-aks-${var.environment}-${var.location}"
      address_prefix = "10.60.1.0/24"
    }
  }

  app_configuration_keys = {
    "task-service" = {
      APP_NAME = "task-service"
      ENV      = "local"
      # DB_HOST     = "postgres"
      # DB_PORT     = "5432"
      # DB_USER     = "postgres"
      # DB_PASSWORD = "postgres"
      DB_NAME   = "tasks"
      LOG_LEVEL = "INFO"
    }
    "audit-service" = {
      DOTNET_USE_POLLING_FILE_WATCHER          = "true"
      DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE = "false"
      AUDIT_STORE                              = "cosmos"
      # COSMOS_ENDPOINT                          = "https://todo6060.documents.azure.com:443/"
      # COSMOS_KEY                               = "<key>"
      # COSMOS_DATABASE                          = "todo-audit"
      # COSMOS_CONTAINER                         = "events"
      COSMOS_CREATE_IF_NOT_EXISTS = "true"
    }
    "api-gateway" = {
      APP_NAME          = "api-gateway"
      PORT              = "3000"
      TASK_SERVICE_HOST = "postgres"
      TASK_SERVICE_PORT = "5432"
      # REDIS_HOST         = "postgres"
      # REDIS_PORT         = "postgres"
      # REDIS_PASSWORD     = "postgres"
      AUDIT_SERVICE_HOST = "tasks"
      AUDIT_SERVICE_PORT = "INFO"
    }
    "task-service" = {
      APP_NAME    = "task-service"
      ENV         = "local"
      DB_HOST     = "postgres"
      DB_PORT     = "5432"
      DB_USER     = "postgres"
      DB_PASSWORD = "postgres"
      DB_NAME     = "tasks"
      LOG_LEVEL   = "INFO"
    }
    "ui" = {
      VITE_API_URL = "task-service"
    }
  }
}
