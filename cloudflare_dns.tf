resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_tunnel.account_id
  name       = var.cloudflare_tunnel.name
  secret     = random_password.tunnel_secret.result
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel" {
  account_id = var.cloudflare_tunnel.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  config {
    ingress_rule {
      hostname = local.node_red_instance.hostname
      service  = "http://${local.node_red_instance.name}:1880"
    }
    ingress_rule { service = "http_status:404" }
  }
}

resource "cloudflare_record" "node_red_cname" {
  zone_id = var.cloudflare_zone_id
  name    = local.node_red_instance.hostname
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
  proxied = var.cloudflare_proxied
}
