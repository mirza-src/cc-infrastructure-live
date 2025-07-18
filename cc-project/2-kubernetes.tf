module "kubernetes" {
  source           = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version          = "0.2.5"
  enable_telemetry = false

  location            = local.location.name
  resource_group_name = module.resource_group.name
  name                = module.naming.kubernetes_cluster.name
  dns_prefix          = module.naming.kubernetes_cluster.name

  kubernetes_version                = "1.33.1"
  sku_tier                          = "Free"
  node_resource_group_name          = "mc_${module.resource_group.name}_${module.naming.kubernetes_cluster.name}"
  oidc_issuer_enabled               = true  # OIDC Issuer for possible federated credentials
  workload_identity_enabled         = true  # Allows Kubernetes workloads to access Azure resources using Azure AD identities
  azure_policy_enabled              = false # Do not deploy Azure Policy addon
  role_based_access_control_enabled = true  # Use Azure RBAC for Kubernetes authorization (other than local service accounts)
  azure_active_directory_role_based_access_control = {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.this.tenant_id
  }

  # Configure cilium as the CNI plugin for Kubernetes networking ( cause we like it :) )
  network_profile = {
    network_plugin      = "azure"
    network_dataplane   = "cilium"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.0.0.0/16"
    service_cidr        = "10.1.0.0/16"
    dns_service_ip      = "10.1.0.10"
  }

  # Using a single smallest possible node as the default system node pool to save cost (this cannot be a spot instance on Azure)
  default_node_pool = {
    name           = "default"
    max_pods       = 250
    node_count     = 1 # No auto-scaling to control costs
    vm_size        = "Standard_B2pls_v2" # Cheapest VM size available on Azure for Kubernetes (but no Ephemeral OS disk)
    os_sku         = "Ubuntu"
    vnet_subnet_id = module.virtual_network.subnets.k8s_nodes.resource_id

    # These values are default but have been added to avoid unexpected drifts
    upgrade_settings = {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  node_pools = {
    spot = {
      name       = "spot"
      vm_size    = "Standard_D2as_v4"
      node_count = 1 # No auto-scaling due to quota limits

      priority        = "Spot"
      eviction_policy = "Delete"
      spot_max_price  = -1

      # Using Ephemeral OS disk for cost efficiency
      os_disk_type    = "Ephemeral"
      os_disk_size_gb = 50
      os_sku          = "Ubuntu"
    }
  }

  managed_identities = {
    system_assigned = true
  }

  role_assignments = {
    # Allow the current user to manage the Kubernetes cluster
    owner = {
      role_definition_id_or_name = "Azure Kubernetes Service RBAC Cluster Admin"
      principal_id               = data.azurerm_client_config.this.object_id
      scope                      = module.kubernetes.resource_id
    }
  }
}

data "azurerm_kubernetes_cluster" "this" {
  resource_group_name = module.resource_group.name
  name                = module.kubernetes.name

  depends_on = [module.kubernetes]
}
