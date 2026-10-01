variable "node_ip" {
  type        = string
  description = "IP of the Proxmox node hosting the container (for pct exec)"
}

variable "vm_id" {
  type        = number
  description = "VMID of the Alpine container"
}
