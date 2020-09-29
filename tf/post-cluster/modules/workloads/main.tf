locals {
  name     = "workload"
  platform_image = {
    go     = "sckmkny/starter-kit-image-go:1.0.0"
    nodejs = "sckmkny/starter-kit-image-nodejs:1.0.0"
  }
}

# FOR EACH WORKLOAD RESOURCES

# DEPLOYMENT

resource "kubernetes_deployment" "this" {
  for_each = var.workload
  lifecycle {
    ignore_changes = [spec[0].template[0].spec[0].container[0].image]
  }
  metadata {
    name = each.key
    labels = {
      "app.kubernetes.io/instance" = each.key
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/version"  = var.sk_version
    }
  }
  spec {
    replicas = each.value["replicas"]
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
          "app.kubernetes.io/version"  = var.sk_version
          instance                     = each.key
        }
      }
      spec {
        container {
          dynamic "env" { // RESOURCE AURORA URL
            for_each = [for resource in each.value["resources"] : resource["id"] if resource["type"] == "aurora"]
            content {
              name  = "${upper(env.value)}_AURORA_URL"
              value = var.aurora_database[env.value].url
            }
          }
          dynamic "env" { // RESOURCE AURORA READER_URL
            for_each = [for resource in each.value["resources"] : resource["id"] if resource["type"] == "aurora"]
            content {
              name  = "${upper(env.value)}_AURORA_READER_URL"
              value = var.aurora_database[env.value].reader_url
            }
          }
          image             = local.platform_image[each.value["platform"]]
          image_pull_policy = "Always"
          name              = local.name
          liveness_probe {
            http_get {
              path = each.value["liveness_probe_path"]
              port = "http"
            }
          }
          port {
            container_port = 8080
            name           = "http"
          }
          readiness_probe {
            http_get {
              path = each.value["readiness_probe_path"]
              port = "http"
            }
          }
          resources {
            limits {
              cpu    = each.value["limits_cpu"]
              memory = each.value["limits_memory"]
            }
            requests {
              cpu    = each.value["requests_cpu"]
              memory = each.value["requests_memory"]
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

resource "kubernetes_service" "this" {
  for_each = var.workload
  metadata {
    name     = each.key
    labels   = {
      "app.kubernetes.io/instance" = each.key
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/version"  = var.sk_version
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
    type = each.value["external"] ? "NodePort" : "ClusterIP"
  }
}
