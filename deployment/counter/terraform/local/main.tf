terraform {  
    required_providers {
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "2.13.1"
        }
    }
}

provider "kubernetes" {
    config_path    = "~/.kube/config"
    config_context = "docker-desktop"
}

module "counter-app" {
    source = "../_modules/counter-app"
    create_namespace = true
    namespace = "counter"
    application_name = "counter"
    replica_number = 1
    
    counter_secrets_name = "counter-secrets"
    docker_repository = "devops/counter"
    docker_version = "latest"
    pull_policy = "Never"

    app_port = 10000
    service_port = 8080

    redis_db = 0
    redis_host = "redis.redis.svc.cluster.local"
    redis_port = 6379
    
    providers = {
      kubernetes = kubernetes
    }
}

module "redis" {
    source = "../_modules/redis"
    create_namespace = true
    namespace = "redis"
    application_name = "redis"
    docker_repository = "redis"
    docker_version = "7-alpine"
    redis_secrets_name = "redis-secrets"
    volume_name = "redis-volume"
    
    redis_port = 6379
    replicas_count  = 2
    
    sentinel_port   = 9000
    sentinels_count = 3
    

    providers = {
      kubernetes = kubernetes
    }
}
