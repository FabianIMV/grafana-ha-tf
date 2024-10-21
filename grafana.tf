resource "kubernetes_deployment" "grafana" {
  metadata {
    name = "grafana"
    labels = {
      app = "grafana"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        container {
          image = "grafana/grafana:latest"
          name  = "grafana"

          port {
            container_port = 3000
          }

          env {
            name  = "GF_DATABASE_TYPE"
            value = "postgres"
          }
          env {
            name  = "GF_DATABASE_HOST"
            value = "postgres:5432"
          }
          env {
            name  = "GF_DATABASE_NAME"
            value = "grafana"
          }
          env {
            name  = "GF_DATABASE_USER"
            value = "grafana"
          }
          env {
            name  = "GF_DATABASE_PASSWORD"
            value = var.postgres_password
          }
          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = var.grafana_admin_password
          }

          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }

          volume_mount {
            name       = "datasources"
            mount_path = "/etc/grafana/provisioning/datasources"
            read_only  = true
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }

        volume {
          name = "grafana-storage"
          empty_dir {}
        }
        
        volume {
          name = "datasources"
          config_map {
            name = kubernetes_config_map.grafana_datasource.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name = "grafana"
  }
  spec {
    selector = {
      app = kubernetes_deployment.grafana.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_config_map" "grafana_datasource" {
  metadata {
    name = "grafana-datasource"
  }

  data = {
    "datasources.yaml" = <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: 'http://prometheus:9090'
    access: proxy
    isDefault: true
  - name: Thanos
    type: prometheus
    url: 'http://thanos-query:9090'
    access: proxy
  - name: Loki
    type: loki
    url: 'http://loki:3100'
    access: proxy
EOF
  }
}