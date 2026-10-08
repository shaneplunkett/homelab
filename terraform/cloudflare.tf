locals {
  cloudflare_zones = {
    "shaneplunkett.com" = "0d155609a60a3280d5ac232e1d3dc4db"
    "shaneplunkett.dev" = "3b5ec3c3b82c6856a8e94284c72d013d"
  }
}

data "cloudflare_account_api_token_permission_groups_list" "dns_write" {
  account_id = var.cloudflare_account_id
  name       = "DNS Write"
  scope      = "com.cloudflare.api.account.zone"
}

import {
  to = cloudflare_account_token.ingress_acme
  id = "${var.cloudflare_account_id}/d46d5cef102872f0b12adb055c5d76fc"
}

resource "cloudflare_account_token" "ingress_acme" {
  account_id = var.cloudflare_account_id
  name       = "homelab nginx"

  policies = [{
    effect = "allow"
    permission_groups = [{
      id = data.cloudflare_account_api_token_permission_groups_list.dns_write.result[0].id
    }]
    resources = jsonencode({
      for name, id in local.cloudflare_zones : "com.cloudflare.api.account.zone.${id}" => "*"
    })
  }]
}
