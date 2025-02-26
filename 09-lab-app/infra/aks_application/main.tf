locals {
  postfix         = "${var.workload}-${var.environment}-${var.location}"
  postfix_no_dash = replace(local.postfix, "-", "")
  rg_group_name   = "rg-${local.postfix}"
  applications = {
    api = {
      name            = "api"
      ip_address_type = "Private"
      image           = "${var.cr}/${var.apiimage}"
      cpu_min         = "500m"
      memory_min      = "256Mi"
      cpu_max         = "0.5"
      memory_max      = "1024Mi"
      port            = 80
      protocol        = "TCP"
      replicas        = 2
    }
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = local.rg_group_name
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.postfix}"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault" "kv" {
  name                = "kv-${local.postfix}"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secret" "sql_user" {
  name         = "sqluser"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "sql_password" {
  name         = "sqlpassword"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_mssql_server" "sql" {
  name                = "sql-${local.postfix}"
  resource_group_name = local.rg_group_name
}

data "azurerm_mssql_database" "sqldb" {
  name      = "sqldb${local.postfix_no_dash}"
  server_id = data.azurerm_mssql_server.sql.id
}

resource "kubernetes_namespace" "api_namespace" {
  metadata {
    labels = {
      app = "api-${local.postfix}"
    }

    name = "api-${local.postfix}"
  }
}

resource "kubernetes_deployment" "app" {
  for_each = local.applications
  metadata {

    namespace = "api-${local.postfix}"
    name      = "${each.value.name}-${local.postfix}"
    labels = {
      app = "${each.value.name}-${local.postfix}"
    }
  }
  spec {
    replicas = each.value.replicas
    selector {
      match_labels = {
        app = "${each.value.name}-${local.postfix}"
      }
    }
    template {
      metadata {
        labels = {
          app = "${each.value.name}-${local.postfix}"
        }
        namespace = "api-${local.postfix}"
      }

      spec {
        container {
          image = each.value.image
          name  = each.value.name
          resources {
            limits = {
              cpu    = each.value.cpu_max
              memory = each.value.memory_max
            }
            requests = {
              cpu    = each.value.cpu_min
              memory = each.value.memory_min
            }
          }
          port {
            container_port = 80
          }

          liveness_probe {
            http_get {
              path = "/"
              port = each.value.port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
          env {
            name  = "SERVER"
            value = data.azurerm_mssql_server.sql.fully_qualified_domain_name
          }
          env {
            name  = "DATABASE"
            value = data.azurerm_mssql_database.sqldb.name
          }
          env {
            name  = "USER"
            value = data.azurerm_key_vault_secret.sql_user.value
          }
          env {
            name  = "PASSWORD"
            value = data.azurerm_key_vault_secret.sql_password.value
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "appservice" {
  metadata {
    name      = "appservice"
    namespace = "api-${local.postfix}"
  }
  spec {
    selector = {
      app = "api-${local.postfix}"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
