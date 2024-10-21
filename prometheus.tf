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

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus",
            "--storage.tsdb.max-block-duration=2h",
            "--storage.tsdb.min-block-duration=2h",
            "--web.enable-lifecycle"
          ]

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }
          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }
        }

        container {
          image = "quay.io/thanos/thanos:v0.30.2"
          name  = "thanos-sidecar"

          args = [
            "sidecar",
            "--tsdb.path=/prometheus",
            "--prometheus.url=http://localhost:9090",
            "--grpc-address=0.0.0.0:10901",
            "--http-address=0.0.0.0:10902"
          ]

          port {
            container_port = 10901
            name           = "grpc"
          }
          port {
            container_port = 10902
            name           = "http"
          }

          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }
        }

        volume {
          name = "prometheus-storage"
          empty_dir {}
        }

        volume {
          name = "prometheus-config"
          config_map {
            name = "prometheus-config"
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name = "prometheus-config"
  }

  data = {
    "prometheus.yml" = <<EOF
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'thanos-prometheus'
    cluster: 'cluster-name'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
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

resource "kubernetes_service" "thanos_sidecar" {
  metadata {
    name = "thanos-sidecar"
  }
  spec {
    selector = {
      app = kubernetes_deployment.prometheus.metadata[0].labels.app
    }
    port {
      port        = 10901
      target_port = 10901
      name        = "grpc"
    }
  }
}
