resource "kubernetes_deployment" "loki" {
  metadata {
    name = "loki"
    labels = {
      app = "loki"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "loki"
      }
    }

    template {
      metadata {
        labels = {
          app = "loki"
        }
      }

      spec {
        security_context {
          fs_group = 10001
          run_as_user = 10001
          run_as_group = 10001
        }

        container {
          image = "grafana/loki:2.8.0"
          name  = "loki"

          security_context {
            read_only_root_filesystem = false
          }

          port {
            container_port = 3100
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/loki"
          }

          volume_mount {
            name       = "storage"
            mount_path = "/data"
          }

          volume_mount {
            name       = "wal"
            mount_path = "/wal"
          }

          args = [
            "-config.file=/etc/loki/local-config.yaml",
          ]

          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.loki_config.metadata[0].name
          }
        }

        volume {
          name = "storage"
          empty_dir {}
        }

        volume {
          name = "wal"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_config_map" "loki_config" {
  metadata {
    name = "loki-config"
  }

  data = {
    "local-config.yaml" = <<EOF
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  wal:
    enabled: true
    dir: /wal
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-05-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /data/loki/index

  filesystem:
    directory: /data/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
EOF
  }
}

resource "kubernetes_service" "loki" {
  metadata {
    name = "loki"
  }

  spec {
    selector = {
      app = kubernetes_deployment.loki.metadata[0].labels.app
    }

    port {
      port        = 3100
      target_port = 3100
    }
  }
}