import {
  to = cloudflare_zero_trust_tunnel_cloudflared.brain
  id = "${var.cloudflare_account_id}/d4f06e81-a579-47e9-ab4a-59bb219fed63"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "brain" {
  account_id = var.cloudflare_account_id
  name       = "brain"
  config_src = "cloudflare"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared_config.brain
  id = "${var.cloudflare_account_id}/d4f06e81-a579-47e9-ab4a-59bb219fed63"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "brain" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.brain.id

  config = {
    ingress = [
      {
        hostname = "vex.shaneplunkett.dev"
        service  = "http://vex-brain:8000"
      },
      {
        service = "http_status:404"
      },
    ]
  }
}
