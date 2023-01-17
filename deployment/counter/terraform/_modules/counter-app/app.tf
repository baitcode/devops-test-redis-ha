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

        container {
          name = "app"
          image = "${var.docker_repository}:${var.docker_version}"
          image_pull_policy = var.pull_policy

          env {
            name = "PORT"
            value = var.app_port
          }

          env {
            name = "REDIS_HOST"
            value = var.redis_host
          }

          env {
            name = "REDIS_PORT"
            value = var.redis_port
          }

          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.counter_secrets_name
                key = "redis_password"
              }
            }
          }

          env {
            name = "REDIS_DB"
            value = var.redis_db
          }
        }
      }
    }
  }
}