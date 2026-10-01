variable "node_ip" {
  type        = string
  description = "IP of the Proxmox node hosting the container (for pct exec)"
}

variable "vm_id" {
  type        = number
  description = "VMID of the container running Tailscale"
}

variable "accept_routes" {
  type        = bool
  default     = false
  description = "Accept subnet routes. Only for machines that live outside the LAN; on a LAN machine it hairpins local traffic through the subnet router"
}
