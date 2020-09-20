locals {
  instance = "ingress"
  name     = "ingress"
  version  = "0.1.0"
}

data "aws_route53_zone" "this" {
  name = "${var.zone_name}."
}

data "aws_lb" "this" {
  depends_on = [
    kubernetes_ingress.this
  ]
  name =  regex("^([^-]+-[^-]+-[^-]+-[^-]+)", kubernetes_ingress.this.load_balancer_ingress[0].hostname)[0]
}

# INGRESS
# ISSUE: DESTROYING INGRESS LEAVES A STRAY SECURITY GROUP IN VPC; PREVENTS DESTROYING VPC

resource "kubernetes_ingress" "this" {
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
      "app.kubernetes.io/version"  = local.version
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

# DNS A RECORD

resource "aws_route53_record" "web" {
  for_each = {for key, workload in var.workload : key => workload if workload["external"]}
  alias {
    name                   = data.aws_lb.this.dns_name
    zone_id                = data.aws_lb.this.zone_id
    evaluate_target_health = true
  }
  name    = "${each.key}.${var.zone_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id
}
