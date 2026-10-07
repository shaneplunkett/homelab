resource "proxmox_virtual_environment_dns" "node" {
  for_each  = toset([local.pve.name, local.cube.name])
  node_name = each.key
  domain    = "shaneplunkett.com"
  servers = [
    "192.168.1.91",
    "192.168.1.236",
    "192.168.1.1",
  ]
}
