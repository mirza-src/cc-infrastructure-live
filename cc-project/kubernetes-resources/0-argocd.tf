resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.1.3"
  namespace        = "argocd"
  create_namespace = true

  values = [file("files/argocd.yaml")]
}

resource "kubectl_manifest" "bootstrap" {
  yaml_body = file("files/bootstrap.yaml")

  lifecycle {
    ignore_changes = all
  }
  depends_on = [helm_release.argocd]
}
