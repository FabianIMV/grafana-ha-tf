output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "grafana_url" {
  description = "URL para acceder a Grafana"
  value       = try("http://localhost:${data.kubernetes_service.grafana.spec[0].port[0].node_port}", "Grafana URL not available yet")
}
data "kubernetes_service" "grafana" {
  metadata {
    name = "grafana"
  }
  
}