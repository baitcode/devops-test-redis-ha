locals {
  master_redis_ports = [
    for i in range(var.masters_count): var.redis_port + i
  ]
  slave_redis_ports = [
    for i in range(var.masters_count*var.replicas_per_master): var.redis_port + var.masters_count + i
  ]
}

resource "kubernetes_config_map" "redis_config" {
  metadata {
    name = "redis-config"
    namespace = data.kubernetes_namespace.ns.id
  }

  data = {

    "redis.conf" = templatefile("${path.module}/conf/redis.conf", {
      redis_port  = var.redis_port,
    })
    
  }
}

resource "kubernetes_config_map" "redis_scripts" {
  metadata {
    name = "redis-scripts"
    namespace = data.kubernetes_namespace.ns.id
  }

  data = {
    "create_cluster.sh" = templatefile("${path.module}/conf/create_cluster.sh", {
      redis_port  = var.redis_port,
      
      master_hosts = [
        for i in range(var.masters_count): 
          "${var.application_name}-master-${i}:${var.redis_port + i}"
      ],
      
      slaves_hosts = [
        for i in range(var.masters_count * var.replicas_per_master): 
          "${var.application_name}-slave-${floor(i / var.replicas_per_master)}-${i % var.replicas_per_master}:${var.redis_port + var.masters_count + i}"
      ],
    })
  }
}


resource "kubernetes_job_v1" "create_cluster" {
  metadata {
    name = "create-cluster"
    namespace = data.kubernetes_namespace.ns.id
  }

  spec {
    template {
      metadata {
        name = "create-cluster"
      }

      spec {
        service_account_name = var.application_name
        automount_service_account_token = true

        volume {
          name = "scripts"

          config_map {
            name = kubernetes_config_map.redis_scripts.metadata[0].name
            default_mode = "0744"
          }
          
          
        }

        container {
          name = "master"
          image = "${var.docker_repository}:${var.docker_version}"
          image_pull_policy = "Always"

          command = [ "/scripts/create_cluster.sh" ] 

          volume_mount {
            name = "scripts"
            mount_path = "/scripts/create_cluster.sh"
            sub_path = "create_cluster.sh"
          }
        }
      }
    }

    backoff_limit = 0
  }

  depends_on = [
    kubernetes_deployment.masters,
    kubernetes_deployment.slaves,
    kubernetes_service.masters_service,
    kubernetes_service.slave_service,
  ]
}