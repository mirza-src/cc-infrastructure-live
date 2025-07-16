locals {
  kube_host                   = data.terraform_remote_state.azure.outputs.kube_host
  kube_cluster_ca_certificate = data.terraform_remote_state.azure.outputs.kube_cluster_ca_certificate
  kube_exec_args = [
    "get-token",
    "--login",
    "spn",
    "--server-id",
    "6dae42f8-4368-4678-94ff-3960e28e3630", # Azure Kubernetes Service AAD Server, service principal managed by Azure
    "--tenant-id",
    var.azure_tenant_id,
    "--client-id",
    var.azure_client_id,
    "--client-secret",
    var.azure_client_secret,
  ]
}

data "terraform_remote_state" "azure" {
  backend = "azurerm"
  config = {
    resource_group_name  = "infrastructure-bootstrap"
    storage_account_name = "stinfragwc"
    container_name       = "terraform"
    key                  = "cc-project/terraform.tfstate"
    use_oidc             = true
  }
}

provider "kubectl" {
  host                   = local.kube_host
  cluster_ca_certificate = local.kube_cluster_ca_certificate
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = local.kube_exec_args
  }
}

provider "helm" {
  kubernetes {
    host                   = local.kube_host
    cluster_ca_certificate = local.kube_cluster_ca_certificate
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = local.kube_exec_args
    }
  }
}
