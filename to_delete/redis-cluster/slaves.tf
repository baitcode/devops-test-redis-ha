
resource "kubernetes_deployment" "slaves" {
  count = var.masters_count * var.replicas_per_master

  metadata {
    name = "${var.application_name}-slave-${floor(count.index / var.replicas_per_master)}-${count.index % var.replicas_per_master}"
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
        role = "slave"
      }
    }

    template {
      metadata {
        labels = {
          application = var.application_name
          index = count.index
          role = "slave"
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

          command = [ 
            "redis-server", 
            "/config/redis.conf", 
            "--port", var.redis_port + var.masters_count + count.index
          ]

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

resource "kubernetes_service" "slave_service" {
  count = var.masters_count * var.replicas_per_master

  metadata {
    name = "${var.application_name}-slave-${floor(count.index / var.replicas_per_master)}-${count.index % var.replicas_per_master}"
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {

    selector = {
      application = var.application_name
      index = count.index
      role = "slave"
    }

    port {
      port = var.redis_port + var.masters_count + count.index
      target_port = var.redis_port + var.masters_count + count.index
      protocol = "TCP"
    }

    type = "ClusterIP"
  } 
}