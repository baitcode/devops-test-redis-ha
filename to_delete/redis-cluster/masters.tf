
resource "kubernetes_deployment" "masters" {
  count = var.masters_count

  metadata {
    name = "${var.application_name}-master-${count.index}"
    namespace = data.kubernetes_namespace.ns.id
    labels = {}
    annotations = {}
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        application = var.application_name
        index = count.index
        role = "master"
      }
    }

    template {
      metadata {
        labels = {
          application = var.application_name
          index = count.index
          role = "master"
        }
      }

      spec {
        service_account_name = var.application_name
        automount_service_account_token = true
        host_network = var.host_network

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.redis_config.metadata[0].name
          }
        }

        container {
          name = "master"
          image = "${var.docker_repository}:${var.docker_version}"
          image_pull_policy = "Always"

          command = [ "redis-server", "/config/redis.conf", "--port", var.redis_port + count.index] # TODO: add password

          volume_mount {
            name = "config"
            mount_path = "/config/redis.conf"
            sub_path = "redis.conf"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "masters_service" {
  count = var.masters_count

  metadata {
    name = "${var.application_name}-master-${count.index}"
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {
    selector = {
      application = var.application_name
      index = count.index
      role = "master"
    }

    port {
      port = var.redis_port + count.index
      target_port = var.redis_port + count.index
      protocol = "TCP"
    }

    type = "ClusterIP"
  } 
}
