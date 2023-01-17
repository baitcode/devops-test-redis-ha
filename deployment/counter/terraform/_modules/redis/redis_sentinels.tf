resource "kubernetes_config_map" "redis_sentinel_config" {
  count = var.sentinels_count

  metadata {
    name = "redis-sentinel-config-${count.index}"
    namespace = data.kubernetes_namespace.ns.id
  }

  data = {
    "redis.conf" = templatefile("${path.module}/conf/redis_sentinel.conf", {
      redis_port    = var.redis_port,
      sentinel_host = "${var.application_name}-sentinel-${count.index}"
      sentinel_port = var.sentinel_port
      master_host   = "${var.application_name}-master"
      master_port   = var.redis_port
      quorum        = var.sentinels_count / 2 + 1
    })
  }
}

resource "kubernetes_stateful_set" "redis_sentinels" {
  count = var.sentinels_count
  
  metadata {
    name = "${var.application_name}-sentinel-${count.index}"
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
        role = "sentinel"
        group = "ha"
        index = count.index
      }
    }

    template {
      metadata {
        labels = {
          application = var.application_name
          role = "sentinel"
          group = "ha"
          index = count.index
        }
      }

      spec {
        service_account_name = var.application_name
        automount_service_account_token = true

        volume {
          name = "config"

          config_map {
            name = "redis-sentinel-config-${count.index}"
            default_mode = "0777"
          }
        }

        container {
          name = var.application_name
          image = "${var.docker_repository}:${var.docker_version}"
          image_pull_policy = "Always"
          args = ["redis-server /data/redis.conf --sentinel --requirepass $REDIS_PASSWORD"]
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
            name = "redis-data-sentinel-${count.index}"
            mount_path = "/data/"

          }
        }

        init_container {
          name = "init"
          image = "bash:5-alpine3.16"
          command = ["sh", "-c"]
          args = ["cp /config/redis.conf /data/redis.conf && echo \"sentinel auth-pass master $REDIS_PASSWORD\" >> /data/redis.conf"]
          
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
            name = "redis-data-sentinel-${count.index}"
            mount_path = "/data/"
          }
          
          volume_mount {
            name = "config"
            mount_path = "/config/redis.conf"
            sub_path = "redis.conf"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "redis-data-sentinel-${count.index}"
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
    kubernetes_config_map.redis_sentinel_config
  ]
}

resource "kubernetes_service" "sentinels_service" {
  count = var.sentinels_count

  metadata {
    name = "${var.application_name}-sentinel-${count.index}"
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {
    selector = {
      application = var.application_name
      role = "sentinel"
      index = count.index
    }

    port {
      port = var.sentinel_port
      target_port = var.sentinel_port
      protocol = "TCP"
    }

    type = "ClusterIP"
  } 
}
