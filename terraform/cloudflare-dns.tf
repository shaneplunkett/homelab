locals {
  dns_record_definitions = {
    "com/CNAME/redbook" = {
      record_id = "3d9728f13842f05d80c852646c44c709"
      zone      = "shaneplunkett.com"
      type      = "CNAME"
      name      = "redbook.shaneplunkett.com"
      content   = "red-book-5nn.pages.dev"
      proxied   = true
    }
    "com/MX/alt1" = {
      record_id = "5528fe708d7abb756079143aefded194"
      zone      = "shaneplunkett.com"
      type      = "MX"
      name      = "shaneplunkett.com"
      content   = "alt1.aspmx.l.google.com"
      ttl       = 3600
      priority  = 5
    }
    "com/MX/alt2" = {
      record_id = "7ef9c7047985da1ca81f03038130ede4"
      zone      = "shaneplunkett.com"
      type      = "MX"
      name      = "shaneplunkett.com"
      content   = "alt2.aspmx.l.google.com"
      ttl       = 3600
      priority  = 5
    }
    "com/MX/alt3" = {
      record_id = "c1511dbdb408b428975796f909ae12f7"
      zone      = "shaneplunkett.com"
      type      = "MX"
      name      = "shaneplunkett.com"
      content   = "alt3.aspmx.l.google.com"
      ttl       = 3600
      priority  = 10
    }
    "com/MX/alt4" = {
      record_id = "e01f3ae28babc70058bf660357641e46"
      zone      = "shaneplunkett.com"
      type      = "MX"
      name      = "shaneplunkett.com"
      content   = "alt4.aspmx.l.google.com"
      ttl       = 3600
      priority  = 10
    }
    "com/MX/aspmx" = {
      record_id = "c260ae35f7584889f15433cd00844703"
      zone      = "shaneplunkett.com"
      type      = "MX"
      name      = "shaneplunkett.com"
      content   = "aspmx.l.google.com"
      ttl       = 3600
      priority  = 1
    }
    "com/TXT/*._domainkey" = {
      record_id = "812207b7d962d48efbdbbd5ddf1c7579"
      zone      = "shaneplunkett.com"
      type      = "TXT"
      name      = "*._domainkey.shaneplunkett.com"
      content   = "\"v=DKIM1;k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAm9Wl98OEHqej/MXrN0VFYxXFlBbieUul/DSXq+mKiBl6oSenN90SNlxxC4WKZJNHGPjWLtJhGjAO+sCGHeC0MOpBlNLdOOBviRifYOuUWvPWhFL90VaP5A60RaqKNnjcs69ZAnhy0gFNKl1r9BmEI7RPBoD4kmfMw4JvNXoqn//auYbMCq3ecI7AOqSMIstnzTQ\" \"vn1EeqWZ2ycFymhqMh/+Y1CKg4HvqfMIuncQ9WTMo6kJNk6IQDCx0WjZ+HBsqMXoe5wPZ9xqykB05F5nXFsmbN4cCz8Of03+Vm0Bj8mgyZdOaHHDGGURg/+HI+Fh4/9Dt04HxiK1KGmPTy83lyQIDAQAB\""
    }
    "com/TXT/_dmarc" = {
      record_id = "ddb5f5b8d49e3fae46f3db8d9a774a86"
      zone      = "shaneplunkett.com"
      type      = "TXT"
      name      = "_dmarc.shaneplunkett.com"
      content   = "\"v=DMARC1; p=quarantine; rua=mailto:6e0a0ed52a3e4164a2c2306cc5f74054@dmarc-reports.cloudflare.net\""
    }
    "com/TXT/google-verification" = {
      record_id = "7edaa142e2719bf517d16a3a3bdccd4c"
      zone      = "shaneplunkett.com"
      type      = "TXT"
      name      = "shaneplunkett.com"
      content   = "\"google-site-verification=Ru7FKVb_ynpMlcjm9Wuvl9v9MN0vvptD00dgTGlgvHA\""
      ttl       = 3600
    }
    "com/TXT/spf" = {
      record_id = "665008ab9b8850b9428207453d8d487d"
      zone      = "shaneplunkett.com"
      type      = "TXT"
      name      = "shaneplunkett.com"
      content   = "\"v=spf1 include:_spf.google.com ~all\""
      ttl       = 3600
    }
    "dev/CNAME/vex" = {
      record_id = "a49bcc31f8a34ee5095e4bc26a22139c"
      zone      = "shaneplunkett.dev"
      type      = "CNAME"
      name      = "vex.shaneplunkett.dev"
      content   = "d4f06e81-a579-47e9-ab4a-59bb219fed63.cfargotunnel.com"
      proxied   = true
    }
    "dev/MX/alt1" = {
      record_id = "ccd95997258527823aec97e3ad525c85"
      zone      = "shaneplunkett.dev"
      type      = "MX"
      name      = "shaneplunkett.dev"
      content   = "alt1.aspmx.l.google.com"
      ttl       = 3600
      priority  = 5
    }
    "dev/MX/alt2" = {
      record_id = "e9431c7e0f23cf65a1bb358b0992c77a"
      zone      = "shaneplunkett.dev"
      type      = "MX"
      name      = "shaneplunkett.dev"
      content   = "alt2.aspmx.l.google.com"
      ttl       = 3600
      priority  = 5
    }
    "dev/MX/alt3" = {
      record_id = "7d1340ab44026afe7aed5767e78d6019"
      zone      = "shaneplunkett.dev"
      type      = "MX"
      name      = "shaneplunkett.dev"
      content   = "alt3.aspmx.l.google.com"
      ttl       = 3600
      priority  = 10
    }
    "dev/MX/alt4" = {
      record_id = "a75730ecea95790d7b5921f142ea2f7c"
      zone      = "shaneplunkett.dev"
      type      = "MX"
      name      = "shaneplunkett.dev"
      content   = "alt4.aspmx.l.google.com"
      ttl       = 3600
      priority  = 10
    }
    "dev/MX/aspmx" = {
      record_id = "5e97021429190e2c148a2be3362624ac"
      zone      = "shaneplunkett.dev"
      type      = "MX"
      name      = "shaneplunkett.dev"
      content   = "aspmx.l.google.com"
      ttl       = 3600
      priority  = 1
    }
    "dev/TXT/_dmarc" = {
      record_id = "de5d6c5d727a8e1c135c9c221b29dba9"
      zone      = "shaneplunkett.dev"
      type      = "TXT"
      name      = "_dmarc.shaneplunkett.dev"
      content   = "\"v=DMARC1;p=reject;pct=100;rua=mailto:24b4411b41b143f3b98550df738e0074@dmarc-reports.cloudflare.net\""
    }
    "dev/TXT/google-verification" = {
      record_id = "82655cf13b30a6f5a2d7d935501c709c"
      zone      = "shaneplunkett.dev"
      type      = "TXT"
      name      = "shaneplunkett.dev"
      content   = "\"google-site-verification=ZYNe9FCXHM9OhcljqWO5Tn-KRirgSWcKatlVZTWPq_s\""
      ttl       = 3600
    }
    "dev/TXT/google._domainkey" = {
      record_id = "92d8c375778099bc706e9f70a53ac5ea"
      zone      = "shaneplunkett.dev"
      type      = "TXT"
      name      = "google._domainkey.shaneplunkett.dev"
      content   = "\"v=DKIM1;k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApOqY12clUlgmd4T0bR95U+jLkl2BoEzFIH+oHTCiIlcqeeE9kDILyXnGn9p89WR65RhNHWd6PX8ewnjigX/5IBXOypqE/zK6FFK6Di6KYEvLK3HYKspAMv/Cm664uSTl8RamTX+Jj4Ac5lZ425JgjZSidvjOWB5LzsmJL9ud3vA8HMhwTo8CVO6Mn5mQT7zpkvN\" \"3ZR1Yrh5vTreeRjMwKbsoTuc/AFP6K9vt3ILmHOON/Lwc7mHF/oYkj07PC+37uRQFobRa0O8ddW7FSLTBgWoE63gaJjSXm0o7iUaMLdXzHGq9A6seyQH3g1CE0UZN451srBTpe6KakcEj+V7grQIDAQAB\""
      ttl       = 60
    }
    "dev/TXT/spf" = {
      record_id = "abd00c210c80519b066cb9c930177227"
      zone      = "shaneplunkett.dev"
      type      = "TXT"
      name      = "shaneplunkett.dev"
      content   = "\"v=spf1 include:_spf.google.com ~all\""
      ttl       = 3600
    }
  }

  dns_records = {
    for key, record in local.dns_record_definitions : key => merge({ ttl = 1, priority = null, proxied = false }, record)
  }
}

import {
  for_each = local.dns_records
  to       = cloudflare_dns_record.this[each.key]
  id       = "${local.cloudflare_zones[each.value.zone]}/${each.value.record_id}"
}

resource "cloudflare_dns_record" "this" {
  for_each = local.dns_records

  zone_id  = local.cloudflare_zones[each.value.zone]
  type     = each.value.type
  name     = each.value.name
  content  = each.value.content
  ttl      = each.value.ttl
  priority = each.value.priority
  proxied  = each.value.proxied
}

import {
  for_each = local.cloudflare_zones
  to       = cloudflare_zone_dnssec.this[each.key]
  id       = each.value
}

resource "cloudflare_zone_dnssec" "this" {
  for_each = local.cloudflare_zones

  zone_id = each.value
  status  = "active"
}
