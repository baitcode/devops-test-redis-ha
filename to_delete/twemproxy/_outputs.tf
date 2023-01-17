output "namespace" {
    value = data.kubernetes_namespace.ns.id
}

output "host" {
    value = var.application_name
}

output "port" {
    value = var.app_port
}