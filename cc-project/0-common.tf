locals {
  location        = module.regions.regions_by_name.centralindia # Using Central India as it is generally the cheapest region
  naming_suffixes = ["cc", "project", "ci"]
}

# Current `user` configuration
data "azurerm_client_config" "this" {}

# Information about the available Azure regions
module "regions" {
  source           = "Azure/avm-utl-regions/azurerm"
  version          = "0.5.2"
  enable_telemetry = false
}

# For ensuring consistent naming across resources
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = local.naming_suffixes
}

module "resource_group" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "0.2.1"
  enable_telemetry = false

  location = local.location.name
  name     = module.naming.resource_group.name
}
