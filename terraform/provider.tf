provider "proxmox" {
  endpoint  = local.pve.api_url
  api_token = var.pve_api_token
  insecure  = true

  ssh {
    agent    = true
    username = "shane"

    node {
      name    = local.pve.name
      address = local.pve.ip
    }
    node {
      name    = local.cube.name
      address = local.cube.ip
    }
  }
}
