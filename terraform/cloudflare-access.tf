locals {
  access_policies = {
    redbook_editor = "274a02ac-fb51-4464-8a68-5cb0b54a7a49"
    vex_cli        = "c012fc13-962e-4733-a496-7f37299f52fe"
  }
}

import {
  to = cloudflare_zero_trust_access_application.redbook_admin
  id = "accounts/${var.cloudflare_account_id}/c7709927-3f72-4a75-a91d-08e973db7ab5"
}

resource "cloudflare_zero_trust_access_application" "redbook_admin" {
  account_id                = var.cloudflare_account_id
  name                      = "redbook"
  type                      = "self_hosted"
  domain                    = "redbook.shaneplunkett.com/admin"
  destinations              = [{ type = "public", uri = "redbook.shaneplunkett.com/admin" }]
  allowed_idps              = ["5c0c08a3-c3cb-4d00-8206-64dbda4529e6"]
  auto_redirect_to_identity = true
  app_launcher_visible      = true
  session_duration          = "24h"
  policies                  = [{ id = local.access_policies.redbook_editor, precedence = 1 }]

  allow_authenticate_via_warp = false
  enable_binding_cookie       = false
  http_only_cookie_attribute  = false
  options_preflight_bypass    = false
}

import {
  to = cloudflare_zero_trust_access_application.vex
  id = "accounts/${var.cloudflare_account_id}/abd56954-7891-42dd-a331-e9e1113d2f1e"
}

resource "cloudflare_zero_trust_access_application" "vex" {
  account_id           = var.cloudflare_account_id
  name                 = "vex"
  type                 = "self_hosted"
  domain               = "vex.shaneplunkett.dev"
  destinations         = [{ type = "public", uri = "vex.shaneplunkett.dev" }]
  app_launcher_visible = true
  session_duration     = "24h"
  policies             = [{ id = local.access_policies.vex_cli, precedence = 1 }]

  auto_redirect_to_identity  = false
  enable_binding_cookie      = false
  http_only_cookie_attribute = false
  options_preflight_bypass   = false
}
