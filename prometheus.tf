resource "kubernetes_deployment" "prometheus" {
  metadata {
    name = "prometheus"
    labels = {
      app = "prometheus"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          image = "prom/prometheus:v2.30.3"
          name  = "prometheus"

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }
        }

        volume {
          name = "prometheus-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.prometheus_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "prometheus_pvc" {
  metadata {
    name = "prometheus-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = "hostpath"
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name = "prometheus"
  }
  spec {
    selector = {
      app = kubernetes_deployment.prometheus.metadata[0].labels.app
    }
    port {
      port        = 9090
      target_port = 9090
    }
  }
}