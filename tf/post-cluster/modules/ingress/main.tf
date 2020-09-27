locals {
  instance = "ingress"
  name     = "ingress"
}

data "aws_route53_zone" "this" {
  name = "${var.zone_name}."
}

data "aws_lb" "this" {
  count = length({for key, workload in var.workload : key => workload if workload["external"]}) == 0 ? 0 : 1
  depends_on = [
    kubernetes_ingress.this
  ]
  name = regex("^([^-]+-[^-]+-[^-]+-[^-]+)", kubernetes_ingress.this[0].load_balancer_ingress[0].hostname)[0]
}

# AT LEAST ONE WORKLOAD RESOURCES

# INGRESS

# https://kubernetes-sigs.github.io/aws-alb-ingress-controller/guide/tasks/ssl_redirect/
resource "kubernetes_ingress" "this" {
  count = length({for key, workload in var.workload : key => workload if workload["external"]}) == 0 ? 0 : 1
  metadata {
    annotations = {
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
      "alb.ingress.kubernetes.io/certificate-arn"      = var.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "kubernetes.io/ingress.class"                    = "alb"
    }
    name = local.instance
    labels = {
      "app.kubernetes.io/instance" = local.instance
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/version"  = var.sk_version
    }
  }
  spec {
    dynamic "rule" {
      for_each = {for key, workload in var.workload : key => workload if workload["external"]}
      content {
        host = "${rule.key}.${var.zone_name}"
        http {
          path {
            backend {
              service_name = "ssl-redirect"
              service_port = "use-annotation"
            }
            path = "/*"
          }
          path {
            backend {
              service_name = rule.key
              service_port = 80
            }
            path = "/*"
          }
        }
      }
    }
  }
  wait_for_load_balancer = true
}

# FOR EACH WORKLOAD RESOURCES

# DNS A RECORD

resource "aws_route53_record" "web" {
  for_each = {for key, workload in var.workload : key => workload if workload["external"]}
  alias {
    name                   = data.aws_lb.this[0].dns_name
    zone_id                = data.aws_lb.this[0].zone_id
    evaluate_target_health = false
  }
  name    = "${each.key}.${var.zone_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id
}
