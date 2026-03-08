locals {
  pve = {
    ip      = var.pve_ip
    name    = "pve"
    api_url = "https://${var.pve_ip}:8006"
  }
  cube = {
    ip   = var.cube_ip
    name = "cube"

  }
}
