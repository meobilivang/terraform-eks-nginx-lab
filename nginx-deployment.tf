# Configure kubeconfig for connection to EKS cluster
provider "kubernetes" {
  host                   = aws_eks_cluster.eks-lab.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks-lab.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

#######################
# Deploying NGINX
#######################

# NGINX deployment
resource "kubernetes_deployment" "nginx_test" {
  # wait until the node group is ready
  depends_on = [aws_eks_node_group.node-group-1]

  metadata {
    name = var.web_server
  }
  spec {
    replicas = 3

    selector {
      match_labels = {
        app = var.web_server
      }
    }
    template {
      metadata {
        labels = {
          app = var.web_server
        }
      }
      spec {

        # Anti-affinity rule: 1 NGINX pod / 1 worker node
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "app"
                  operator = "In"
                  values   = [var.web_server]
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }

        container {
          image = var.web_server_img
          name  = "nginx-container"

          port {
            container_port = 80
          }

          # Customize index.html
          command = [
            "sh", "-c",
            join("", ["echo \"<html><body>\" >/usr/share/nginx/html/index.html;",
              "echo \"<h2>Pod: $POD_NAME</h2>\n<h2>Node: $NODE_NAME</h2><h2>Namespace: $POD_NAMESPACE</h2>\n<h2>IP: $POD_IP</h2>\" >>/usr/share/nginx/html/index.html;",
              "echo \"</body></html>\" >>/usr/share/nginx/html/index.html;",
          "nginx -g 'daemon off;'"])]

          # resource limit
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          # Inject data about the Pod(s) as env vars to container(s)
          # Refer: https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

        }
      }
    }
  }
}

# Set up NGINX service
resource "kubernetes_service" "nginx_lb" {
  depends_on = [kubernetes_deployment.nginx_test]

  metadata {
    name = var.web_server
    # use a Network LB
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }
  spec {
    selector = {
      app = var.web_server
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
