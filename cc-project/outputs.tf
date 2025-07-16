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
