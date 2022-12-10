

locals {
  location = "West Europe"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-workshop-rg"
  location = local.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-workshop-vnet"
  location            = local.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/8"]
}
