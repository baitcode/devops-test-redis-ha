resource "kubernetes_config_map" "redis_master_config" {
  metadata {
    name = "redis-master-config"
    namespace = data.kubernetes_namespace.ns.id
  }

  data = {
    "redis.conf" = templatefile("${path.module}/conf/redis_master.conf", {
      redis_port  = var.redis_port,
    })
  }
}

resource "kubernetes_stateful_set" "redis_master" {

  metadata {
    name = "${var.application_name}-master"
    namespace = data.kubernetes_namespace.ns.id
    labels = {}
    annotations = {}
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5

    service_name = var.application_name

    selector {
      match_labels = {
        application = var.application_name
        group = "service"
        role = "master"
      }
    }

    template {
      metadata {
        labels = {
          application = var.application_name
          group = "service"
          role = "master"
        }
      }

      spec {
        service_account_name = var.application_name
        automount_service_account_token = true

        volume {
          name = "config"

          config_map {
            name = "redis-master-config"
          }
        }

        container {
          name = var.application_name
          image = "${var.docker_repository}:${var.docker_version}"
          image_pull_policy = "Always"
          args = ["redis-server /config/redis.conf --requirepass $REDIS_PASSWORD"]
          command = ["sh", "-c"] 

          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.redis_secrets_name
                key = "password"
              }
            }
          }

          volume_mount {
            name = "config"
            mount_path = "/config/redis.conf"
            sub_path = "redis.conf"
          }

          volume_mount {
            name = "redis-data-master"
            mount_path = "/data/"
          }
        }


      }
    }

    volume_claim_template {
      metadata {
        name = "redis-data-master"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "500M"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_config_map.redis_master_config
  ]
}

resource "kubernetes_service" "masters_service" {
  metadata {
    name = "${var.application_name}-master"
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {
    selector = {
      application = var.application_name
      role = "master"
    }

    port {
      port = var.redis_port
      target_port = var.redis_port
      protocol = "TCP"
    }

    type = "ClusterIP"
  } 
}
