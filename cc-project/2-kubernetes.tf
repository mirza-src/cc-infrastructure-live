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

  // Configure cilium as the CNI plugin for Kubernetes networking ( cause we like it :) )
  network_profile = {
    network_plugin      = "azure"
    network_dataplane   = "cilium"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.0.0.0/16"
    service_cidr        = "10.1.0.0/16"
    dns_service_ip      = "10.1.0.10"
  }

  // Using a single smallest possible node as the default system node pool to save cost (this cannot be a spot instance on Azure)
  default_node_pool = {
    name           = "default"
    max_pods       = 250
    node_count     = 1
    vm_size        = "Standard_B2pls_v2" # Cheapest VM size available on Azure for Kubernetes
    os_sku         = "Ubuntu"
    vnet_subnet_id = module.virtual_network.subnets.k8s_nodes.resource_id
  }

  managed_identities = {
    system_assigned = true
  }

  role_assignments = {
    owner = { // Allow the current user to manage the Kubernetes cluster
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
