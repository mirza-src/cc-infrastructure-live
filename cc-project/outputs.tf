output "kube_host" {
  value = nonsensitive(data.azurerm_kubernetes_cluster.this.kube_config[0].host)
}

output "kube_oidc_issuer" {
  value = data.azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kube_cluster_ca_certificate" {
  value     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
  sensitive = true
}

output "dns_zone" {
  value = {
    name         = azurerm_dns_zone.this.name
    name_servers = azurerm_dns_zone.this.name_servers
    contributor = {
      name         = azurerm_user_assigned_identity.dns_contributor.name
      client_id    = azurerm_user_assigned_identity.dns_contributor.client_id
      principal_id = azurerm_user_assigned_identity.dns_contributor.principal_id
    }
  }
}
