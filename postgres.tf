resource "kubernetes_deployment" "postgres" {
  metadata {
    name = "postgres"
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          image = "postgres:13"
          name  = "postgres"

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_DB"
            value = "grafana"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.postgres_password
          }
          env {
            name  = "POSTGRES_USER"
            value = "grafana"
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgres"
          }
        }

        volume {
          name = "postgres-storage"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name = "postgres"
  }
  spec {
    selector = {
      app = kubernetes_deployment.postgres.metadata[0].labels.app
    }
    port {
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}