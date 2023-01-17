resource "kubernetes_namespace" "ns" {
  count = var.create_namespace ? 1 : 0
  
  metadata {
    labels = {

    }
    name = var.namespace
  }
}

data "kubernetes_namespace" "ns" {
  metadata {
    name = var.namespace
  }

  depends_on = [
    kubernetes_namespace.ns
  ]
}

resource "kubernetes_service_account" "app" {
  metadata {
    name = var.application_name
    namespace = data.kubernetes_namespace.ns.id
    annotations = {}
  }
}
