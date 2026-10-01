# Pins Tailscale's accept-routes on an LXC at every boot. pve advertises
# 192.168.1.0/24, so a LAN container with accept-routes on replies to LAN
# clients via the tunnel and they never hear back (mcphub, 2026-10-01).
# Re-asserting it at boot means a stray `tailscale up --accept-routes`
# only lasts until the next reboot.
#
# Also installs tailscale from edge: stable Alpine branches freeze it at
# whatever version shipped, so it falls far behind (3.22 is stuck on
# 1.86). It's a static Go binary, so edge builds run fine on stable, and
# the nightly apk-cron upgrade then keeps it current.

locals {
  init_script = <<-SCRIPT
#!/sbin/openrc-run

description="Pin Tailscale accept-routes (managed by Terraform)"

depend() {
    need tailscale
}

# tailscaled takes a moment to accept commands after its service starts
start() {
    ebegin "Setting tailscale accept-routes=${var.accept_routes}"
    i=0
    until tailscale set --accept-routes=${var.accept_routes} 2>/dev/null; do
        i=$((i + 1))
        [ $i -ge 30 ] && break
        sleep 1
    done
    [ $i -lt 30 ]
    eend $?
}
SCRIPT

  provision_script = <<-SCRIPT
set -e

before="$(tailscale version 2>/dev/null | head -1)"
grep -q '^@edge-community ' /etc/apk/repositories ||
  echo '@edge-community https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
apk add --no-cache tailscale@edge-community

echo ${base64encode(local.init_script)} | base64 -d > /etc/init.d/tailscale-lan
chmod 755 /etc/init.d/tailscale-lan
rc-update add tailscale-lan default

# apk doesn't restart services, so pick up a new binary now. Stop rather
# than restart: restarting tailscale also restarts tailscale-lan in the
# background, which races the restart below
[ "$before" = "$(tailscale version | head -1)" ] || rc-service tailscale stop
# brings tailscale back up first if it was stopped
rc-service tailscale-lan restart
SCRIPT
}

resource "terraform_data" "tailscale_lan" {
  triggers_replace = {
    node_ip = var.node_ip
    vm_id   = var.vm_id
    script  = sha256(local.provision_script)
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no shane@${var.node_ip} 'echo ${base64encode(local.provision_script)} | base64 -d | sudo pct exec ${var.vm_id} -- sh -s'"
  }
}
