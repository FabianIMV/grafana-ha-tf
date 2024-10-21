# ConfigMap para Thanos Store con configuración de almacenamiento local
resource "kubernetes_config_map" "thanos_store_config" {
  metadata {
    name = "thanos-store-config"
  }

  data = {
    "thanos-objstore.yml" = <<EOF
type: "FILESYSTEM"
config:
  directory: "/var/thanos/store"
EOF
  }
}

# Despliegue de Thanos Query
resource "kubernetes_deployment" "thanos_query" {
  metadata {
    name = "thanos-query"
    labels = {
      app = "thanos-query"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "thanos-query"
      }
    }

    template {
      metadata {
        labels = {
          app = "thanos-query"
        }
      }

      spec {
        container {
          image = "quay.io/thanos/thanos:v0.30.2"
          name  = "thanos-query"

          args = [
            "query",
            "--http-address=0.0.0.0:9090",
            "--store=dnssrv+_grpc._tcp.thanos-store",
            "--store=dnssrv+_grpc._tcp.thanos-sidecar"
          ]

          port {
            container_port = 9090
          }
        }
      }
    }
  }
}

# Servicio para Thanos Query
resource "kubernetes_service" "thanos_query" {
  metadata {
    name = "thanos-query"
  }
  spec {
    selector = {
      app = kubernetes_deployment.thanos_query.metadata[0].labels.app
    }
    port {
      port        = 9090
      target_port = 9090
    }
  }
}

# Despliegue de Thanos Store usando almacenamiento local
resource "kubernetes_deployment" "thanos_store" {
  metadata {
    name = "thanos-store"
    labels = {
      app = "thanos-store"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "thanos-store"
      }
    }

    template {
      metadata {
        labels = {
          app = "thanos-store"
        }
      }

      spec {
        container {
          image = "quay.io/thanos/thanos:v0.30.2"
          name  = "thanos-store"

          args = [
            "store",
            "--data-dir=/var/thanos/store",
            "--grpc-address=0.0.0.0:10901",
            "--http-address=0.0.0.0:10902",
            "--objstore.config-file=/etc/thanos/thanos-objstore.yml"
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
            name       = "data"
            mount_path = "/var/thanos/store"
          }
          volume_mount {
            name       = "thanos-config"
            mount_path = "/etc/thanos"
          }
        }

        volume {
          name = "data"
          empty_dir {}
        }

        volume {
          name = "thanos-config"
          config_map {
            name = kubernetes_config_map.thanos_store_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Servicio para Thanos Store
resource "kubernetes_service" "thanos_store" {
  metadata {
    name = "thanos-store"
  }
  spec {
    selector = {
      app = kubernetes_deployment.thanos_store.metadata[0].labels.app
    }
    port {
      port        = 10901
      target_port = 10901
      name        = "grpc"
    }
  }
}
