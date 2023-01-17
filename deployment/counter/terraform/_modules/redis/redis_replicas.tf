resource "kubernetes_config_map" "redis_replicas_config" {
  metadata {
    name = "redis-replicas-config"
    namespace = data.kubernetes_namespace.ns.id
  }

  data = {
    "redis.conf" = templatefile("${path.module}/conf/redis_replicas.conf", {
      redis_port  = var.redis_port,
      master_host = "${var.application_name}-master"
    })
  }
}

resource "kubernetes_stateful_set" "redis_replicas" {
  count = var.replicas_count

  metadata {
    name = "${var.application_name}-replica-${count.index}"
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
        role = "replica"
        group = "service"
        index = count.index
      }
    }

    template {
      metadata {
        labels = {
          application = var.application_name
          role = "replica"
          group = "service"
          index = count.index
        }
      }

      spec {
        service_account_name = var.application_name
        automount_service_account_token = true

        volume {
          name = "config"

          config_map {
            name = "redis-replicas-config"
          }
        }

        container {
          name = var.application_name
          image = "${var.docker_repository}:${var.docker_version}"
          image_pull_policy = "Always"
          args = ["redis-server /config/redis.conf --requirepass $REDIS_PASSWORD --masterauth $REDIS_PASSWORD"]
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
            name = "redis-data-replica-${count.index}"
            mount_path = "/data/"
          }
        }

      }
    }

    volume_claim_template {
      metadata {
        name = "redis-data-replica-${count.index}"
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
    kubernetes_config_map.redis_replicas_config
  ]
}

resource "kubernetes_service" "replicas_service" {
  count = var.replicas_count

  metadata {
    name = "${var.application_name}-replica-${count.index}"
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {
    selector = {
      application = var.application_name
      role = "replica"
      index = count.index
    }

    port {
      port = var.redis_port
      target_port = var.redis_port
      protocol = "TCP"
    }

    type = "ClusterIP"
  } 
}
