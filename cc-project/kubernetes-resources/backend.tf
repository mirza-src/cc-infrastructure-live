terraform {
  backend "azurerm" {
    resource_group_name  = "infrastructure-bootstrap"
    storage_account_name = "stinfragwc"
    container_name       = "terraform"
    key                  = "cc-project/kubernetes-resources/terraform.tfstate"
    use_oidc             = true
  }
}
