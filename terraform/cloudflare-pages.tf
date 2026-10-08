import {
  to = cloudflare_pages_domain.redbook
  id = "${var.cloudflare_account_id}/red-book/redbook.shaneplunkett.com"
}

resource "cloudflare_pages_domain" "redbook" {
  account_id   = var.cloudflare_account_id
  project_name = "red-book"
  name         = "redbook.shaneplunkett.com"
}
