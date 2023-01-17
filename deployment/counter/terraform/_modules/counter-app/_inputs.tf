variable "create_namespace" {
  type = bool
  default = true
}

variable "namespace" {
  type = string
  default = "counter"
}

variable "application_name" {
  type = string
  default = "counter"
}

variable "replica_count" {
  type = number
}

variable "docker_repository" {
  type = string
}

variable "docker_version" {
  type = string
}

variable "app_port" {
  type = number
  default = 8080
}

variable "service_port" {
  
}

variable "redis_host" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "redis_db" {
  type = number
}

variable "pull_policy" {
  type = string
  default = "Always"
}

variable "counter_secrets_name" {
  type = string
}