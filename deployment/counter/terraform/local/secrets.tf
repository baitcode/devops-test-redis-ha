
resource "kubernetes_secret" "redis_secrets" {
  metadata {
    name = "redis-secrets"
    namespace = module.redis.namespace
  }

  data = {
    password = "P4ssw0rd"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "counter_secrets" {
  metadata {
    name = "counter-secrets"
    namespace = module.counter-app.namespace
  }

  data = {
    redis_password = "P4ssw0rd"
  }

  type = "Opaque"
}
