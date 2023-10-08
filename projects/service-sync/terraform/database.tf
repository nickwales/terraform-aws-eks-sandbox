resource "kubernetes_service_account" "database" {
  metadata {
    name = "database"
  }
}

resource "kubernetes_deployment_v1" "database" {
  metadata {
    name = "database"
    labels = {
      test = "database"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "database"
      }
    }

    template {
      metadata {
        labels = {
          app = "database"
        }
      }

      spec {
        container {
          image = "nicholasjackson/fake-service:v0.25.2"
          name  = "database"

          port {
            container_port = 9090
          }

          env {
            name  = "LISTEN_ADDR"
            value = "0.0.0.0:9090"
          }

          env {
            name  = "NAME"
            value = "Read Only database - running in EKS"
          }

          env {
            name  = "MESSAGE"
            value = "I do not have an ingress"
          }


          liveness_probe {
            http_get {
              path = "/health"
              port = 9090
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "database" {
  metadata {
    name = "database-svc"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "internal" 
    }
    
  }
  spec {
    selector = {
      app = "database"
    }

    port {
      port        = 9090
      target_port = 9090
    }

    type = "LoadBalancer"
  }

}
