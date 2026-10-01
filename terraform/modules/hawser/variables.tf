variable "node_ip" {
  type        = string
  description = "IP of the Proxmox node hosting the container (for pct exec)"
}

variable "vm_id" {
  type        = number
  description = "VMID of the container to install Hawser on"
}

variable "agent_name" {
  type        = string
  description = "Agent name shown in Dockhand"
}

variable "port" {
  type    = number
  default = 2376
}

variable "hawser_version" {
  type        = string
  default     = "0.2.37"
  description = "Hawser release to install (without the leading v)"
}
