locals {
  domain = "mirzaesaaf.me"
}

resource "azurerm_user_assigned_identity" "dns_contributor" {
  location            = local.location.name
  resource_group_name = module.resource_group.name
  name                = "uai-cc-project-dns-contributor"
}

resource "azurerm_federated_identity_credential" "dns_contributor" {
  for_each = {
    external-dns = "system:serviceaccount:ingress:external-dns"
    cert-manager = "system:serviceaccount:ingress:cert-manager"
  }

  resource_group_name = module.resource_group.name
  parent_id           = azurerm_user_assigned_identity.dns_contributor.id
  issuer              = data.azurerm_kubernetes_cluster.this.oidc_issuer_url
  name                = each.key
  subject             = each.value
  audience            = ["api://AzureADTokenExchange"]
}

resource "azurerm_dns_zone" "this" {
  resource_group_name = module.resource_group.name
  name                = local.domain
}

resource "azurerm_role_assignment" "dns_contributor" {
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.dns_contributor.principal_id
  scope                = azurerm_dns_zone.this.id
}
