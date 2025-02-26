variable "workload" {
  type = string
  validation {
    condition     = can(regex("^[\\w-]+$", var.workload))
    error_message = "Workload group name is not valid."
  }
  default = "mgmt"
}

variable "team_name" {
  type = string
  validation {
    condition     = can(regex("^[\\w-]+$", var.team_name))
    error_message = "Team_name group name is not valid."
  }
  default = "vl"
}

variable "environment" {
  type = string
  validation {
    condition     = can(regex("^[\\w-]+$", var.environment))
    error_message = "Environment group name is not valid."
  }
  default = "dev"
}

variable "location" {
  type = string
  validation {
    condition     = can(regex("^[\\w-]+$", var.location))
    error_message = "Location group name is not valid."
  }
  default = "westeurope"
}

variable "kv_id" {
  type = string
}

variable "kv_sql_user" {
  type = string
}

variable "kv_sql_password" {
  type = string
}

variable "sqldb_name" {
  type = string
}

variable "sql_fqdn" {
  type = string
}

variable "aks_name" {
  type = string
}

variable "aks_resource_group" {
  type = string
}

variable "applications" {
  type = map(object({
    cpu_max         = string,
    cpu_min         = string,
    image           = string,
    ip_address_type = string,
    memory_max      = string,
    memory_min      = string,
    name            = string,
    port            = number,
    protocol        = string,
    replicas        = number
  }))
}