module "proxy" {
  source         = "./modules/alpine-lxc"
  hostname       = "proxy"
  node_name      = local.pve.name
  node_ip        = local.pve.ip
  ip             = "dhcp"
  mac_address    = "BC:24:11:65:53:9F"
  cores          = 2
  memory         = 1024
  disk_size      = 8
  nesting        = true
  tailscale      = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
