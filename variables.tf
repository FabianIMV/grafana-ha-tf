variable "kube_config_path" {
  description = "Path to your kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "postgres_password" {
  description = "Password for PostgreSQL"
  type        = string
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
}

variable "release_prefix" {
  description = "Prefix for Helm releases"
  type        = string
  default     = "grafana-hd"
}
