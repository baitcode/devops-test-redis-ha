variable "create_namespace" {
  type = bool
  default = true
}

variable "namespace" {
  type = string
  default = "redis"  
}

variable "application_name" {
  type = string
  default = "redis"
}

variable "docker_repository" {
  type = string  
}

variable "docker_version" {
  type = string
}

variable "redis_port" {
  type = number
  default = 6379
}

variable "sentinel_port" {
  type = number
  default = 9000  
}

variable "redis_secrets_name" {
  type = string
}

variable "volume_name" {
  type = string
}

variable "replicas_count" {
  type = number
}

variable "sentinels_count" {
  type = number
}