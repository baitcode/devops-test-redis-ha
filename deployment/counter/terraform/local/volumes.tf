
resource "kubernetes_persistent_volume" "redis_volume" {
  metadata {
    name = "redis-data"
  }
  
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = ""
    
    persistent_volume_source {
      host_path {
        path = "/tmp/redis"
      }
    }

    capacity = {
      storage = "5Gi"
    }
  }
  
}
