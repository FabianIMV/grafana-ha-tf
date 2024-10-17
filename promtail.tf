resource "kubernetes_daemonset" "promtail" {
  metadata {
    name = "promtail"
    labels = {
      app = "promtail"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "promtail"
      }
    }

    template {
      metadata {
        labels = {
          app = "promtail"
        }
      }

      spec {
        container {
          name  = "promtail"
          image = "grafana/promtail:2.4.0"

          args = [
            "-config.file=/etc/promtail/promtail.yaml"
          ]

          volume_mount {
            name       = "config"
            mount_path = "/etc/promtail"
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }

          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.promtail_config.metadata[0].name
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "promtail_config" {
  metadata {
    name = "promtail-config"
  }

  data = {
    "promtail.yaml" = <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: kubernetes-pods
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - source_labels: [__meta_kubernetes_pod_node_name]
    target_label: __host__
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
  - action: replace
    replacement: \$1
    separator: /
    source_labels:
    - __meta_kubernetes_namespace
    - __meta_kubernetes_pod_name
    target_label: job
  - action: replace
    source_labels:
    - __meta_kubernetes_namespace
    target_label: namespace
  - action: replace
    source_labels:
    - __meta_kubernetes_pod_name
    target_label: pod
  - action: replace
    source_labels:
    - __meta_kubernetes_pod_container_name
    target_label: container
  - replacement: /var/log/pods/*\$1/*.log
    separator: /
    source_labels:
    - __meta_kubernetes_pod_uid
    - __meta_kubernetes_pod_container_name
    target_label: __path__
EOF
  }
}