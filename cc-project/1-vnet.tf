module "virtual_network" {
  source           = "Azure/avm-res-network-virtualnetwork/azurerm"
  version          = "0.9.2"
  enable_telemetry = false

  location            = local.location.name
  resource_group_name = module.resource_group.name
  name                = module.naming.virtual_network.name

  address_space = ["172.16.0.0/16"]
  subnets = {
    k8s_nodes = {
      name             = "k8s-nodes"
      address_prefixes = ["172.16.0.0/24"]
    }
  }
}
