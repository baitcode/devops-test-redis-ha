
resource "kubernetes_service" "service" {
  metadata {
    name = "${var.application_name}"
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {
    selector = {
      application = var.application_name
      group = "service"
    }

    port {
      port = var.redis_port
      target_port = var.redis_port
      protocol = "TCP"
    }

    type = "ClusterIP"
  } 
}
