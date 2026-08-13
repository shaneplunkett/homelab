module "technitium" {
  source         = "./modules/alpine-lxc"
  hostname       = "technitium"
  node_name      = local.pve.name
  node_ip        = local.pve.ip
  ip             = "192.168.1.5/24" # static, outside the Unifi DHCP pool (.6-.254)
  cores          = 1
  memory         = 1024
  disk_size      = 8
  nesting        = true
  tailscale      = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
