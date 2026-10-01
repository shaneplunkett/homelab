variable "node_ip" {
  type        = string
  description = "IP of the Proxmox node hosting the container (for pct exec)"
}

variable "vm_id" {
  type        = number
  description = "VMID of the Alpine container"
}

variable "alpine_branch" {
  type        = string
  default     = "v3.22"
  description = "Alpine release branch for the main/community repos. Bump here to move every LXC (one at a time with -target), then reboot each"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+$", var.alpine_branch))
    error_message = "alpine_branch must look like v3.22."
  }
}
