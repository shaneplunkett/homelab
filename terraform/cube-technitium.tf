module "technitium2" {
  source         = "./modules/alpine-lxc"
  hostname       = "technitium2"
  node_name      = local.cube.name
  node_ip        = local.cube.ip
  ip             = "192.168.1.4/24" # static, outside the Unifi DHCP pool (.6-.254); primary is .5
  cores          = 1
  # 2 GB: matches the primary — blocklists double in RAM during daily updates
  # and .NET has known memory-growth issues
  memory         = 2048
  disk_size      = 8
  nesting        = true
  tailscale      = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
