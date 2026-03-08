resource "proxmox_virtual_environment_container" "this" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = "Managed by Terraform"
  unprivileged  = var.unprivileged
  start_on_boot = var.start_on_boot

  operating_system {
    template_file_id = var.template_file_id
    type             = "alpine"
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    architecture = "amd64"
    cores        = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.disk_size
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    firewall = true
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.ip != "dhcp" ? var.gateway : null
      }
    }
  }

  features {
    nesting = var.nesting
  }

  # Provision via pct exec on the host — works both locally and in CI
  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no shane@${var.node_ip} "\
        sudo pct exec ${self.vm_id} -- sh -c '\
          # Create shane user with sudo
          adduser -D -s /bin/ash shane && \
          apk add --no-cache sudo && \
          echo \"shane ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/shane && \
          chmod 440 /etc/sudoers.d/shane && \

          # SSH key for shane
          mkdir -p /home/shane/.ssh && \
          echo \"${var.ssh_public_key}\" > /home/shane/.ssh/authorized_keys && \
          chown -R shane:shane /home/shane/.ssh && \
          chmod 700 /home/shane/.ssh && \
          chmod 600 /home/shane/.ssh/authorized_keys && \

          # Lock down root SSH
          sed -i \"s/^#*PermitRootLogin.*/PermitRootLogin no/\" /etc/ssh/sshd_config && \
          sed -i \"s/^#*PasswordAuthentication.*/PasswordAuthentication no/\" /etc/ssh/sshd_config && \
          rc-service sshd restart && \

          # Auto-updates via periodic
          apk add --no-cache apk-cron && \
          echo \"#!/bin/sh\" > /etc/periodic/daily/apk-update && \
          echo \"apk update && apk upgrade\" >> /etc/periodic/daily/apk-update && \
          chmod +x /etc/periodic/daily/apk-update && \
          rc-update add crond default && \
          rc-service crond start \
        '"
    EOT
  }
}
