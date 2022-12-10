locals {
  address_space = "10.0.0.0/8"
}

module "network" {
  source = "./modules/network"

  name_prefix = var.name_prefix
  address_space = local.address_space
  subnets = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "vm" {
  source = "./modules/vm"

  name_prefix = var.name_prefix
  subnet_id = module.network.subnet_id
}