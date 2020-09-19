locals {
  name     = "workload"
  version  = "0.1.0"
}

# ECR

resource "aws_ecr_repository" "this" {
  for_each = var.workload
  image_scanning_configuration {
    scan_on_push = true
  }
  name = "${var.identifier}-${each.key}"
  tags = {
    Infrastructure = var.identifier
  }
}

# DEPLOYMENT

resource "kubernetes_deployment" "ignore_changes" {
  for_each = {for key, workload in var.workload : key => workload if !workload["destroy"]}
  lifecycle {
    ignore_changes = all
  }
  metadata {
    name = each.key
    labels = {
      "app.kubernetes.io/instance" = each.key
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/version"  = local.version
    }
  }
  spec {
    replicas = each.value["placeholder_replicas"]
    selector {
      match_labels = {
        instance = each.key
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/instance" = each.key
          "app.kubernetes.io/name"     = local.name
          "app.kubernetes.io/version"  = local.version
          instance                     = each.key
        }
      }
      spec {
        container {
          image             = each.value["placeholder_image"] ? "sckmkny/starter-kit-image-nodejs:1.0.0" : aws_ecr_repository.this[each.key].repository_url
          image_pull_policy = "Always"
          name              = local.name
          liveness_probe {
            http_get {
              path =  "/" # TODO: HC
              port = "http"
            }
          }
          port {
            container_port = 8080
            name           = "http"
          }
          readiness_probe {
            http_get {
              path =  "/" # TODO: HC
              port = "http"
            }
          }
          resources {
            limits {
              cpu    = "100m" # TODO: COME FROM
              memory = "128Mi"
            }
            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_group               = 1000 # ISSUE: https://github.com/hashicorp/terraform-provider-kubernetes/issues/695
            run_as_user                = 1000 # ISSUE: https://github.com/hashicorp/terraform-provider-kubernetes/issues/695
          }
        }
      }
    }
  }
}

/*
resource "kubernetes_service" "this" {
  for_each = var.workload
  metadata {
    name     = each.key
    labels   = {
      "app.kubernetes.io/instance" = each.key
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/version"  = local.version
    }
  }
  spec {
    port {
      port        = 80 
      target_port = 8080
    }
    selector = {
      instance = each.key
    }
    type = "NodePort"
  }
}
*/
