variable "hostname" {
  type        = string
  description = "Container hostname"
}

variable "node_name" {
  type        = string
  description = "Proxmox node to create on"
}

variable "node_ip" {
  type        = string
  description = "IP or Tailscale hostname of the Proxmox node (for pct exec)"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VMID (null for auto-assign)"
  default     = null
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "swap" {
  type    = number
  default = 512
}

variable "disk_size" {
  type    = number
  default = 8
}

variable "ip" {
  type        = string
  description = "IP address in CIDR notation (e.g. 192.168.1.50/24) or 'dhcp'"
}

variable "gateway" {
  type    = string
  default = "192.168.1.1"
}

variable "nesting" {
  type        = bool
  default     = false
  description = "Enable nesting (required for Docker-in-LXC)"
}

variable "unprivileged" {
  type    = bool
  default = true
}

variable "start_on_boot" {
  type    = bool
  default = true
}

variable "template_file_id" {
  type    = string
  default = "local:vztmpl/alpine-3.22-default_20250617_amd64.tar.xz"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content to add for shane user"
}

variable "tailscale" {
  type        = bool
  default     = false
  description = "Install Tailscale and enable TUN device passthrough"
}

variable "mac_address" {
  type        = string
  default     = null
  description = "MAC address for the network interface (preserves DHCP reservations)"
}
