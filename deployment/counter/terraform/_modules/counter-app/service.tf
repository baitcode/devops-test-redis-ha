resource "kubernetes_service" "service" {
  metadata {
    name = var.application_name
    
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {
    selector = {
      application = var.application_name
    }

    port {
      port = var.service_port
      target_port = var.app_port
      protocol = "TCP"
    }

    type = "LoadBalancer"
  } 
}