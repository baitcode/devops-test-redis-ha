resource "kubernetes_config_map" "config" {
  metadata {
    name = "twemproxy-config"
    namespace = data.kubernetes_namespace.ns.id
  }

  data = {
    "twemproxy.yaml" = templatefile("${path.module}/conf/twemproxy.yaml", {
      app_port  = var.app_port,
      redis_hosts = var.redis_hosts
    })
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = var.application_name
    namespace = data.kubernetes_namespace.ns.id
    labels = {}
    annotations = {}
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        application = var.application_name
      }
    }

    template {
      metadata {
        labels = {
          application = var.application_name
        }
      }

      spec {
        service_account_name = var.application_name
        automount_service_account_token = true

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.config.metadata[0].name
          }
        }

        container {
          name = "app"
          image = "${var.docker_repository}:${var.docker_version}"
          image_pull_policy = var.pull_policy

          command = [ "nutcracker", "-c", "/conf/twemproxy.yaml", "-v", "11"]

          volume_mount {
            name = "config"
            mount_path = "/conf/twemproxy.yaml"
            sub_path = "twemproxy.yaml"
          }
        }
      }
    }
  }
}
