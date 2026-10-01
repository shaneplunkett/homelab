# Native Hawser agent (Dockhand remote) as an OpenRC service. Runs outside
# Docker so it survives redeploys of the stacks it manages.
#
# Unlike provisioners on the container itself, this re-runs whenever the
# script changes, so edits here reach existing containers on the next apply.

locals {
  init_script = <<-SCRIPT
#!/sbin/openrc-run

description="Hawser - Dockhand remote agent"
supervisor=supervise-daemon
command=/usr/local/bin/hawser
command_args="standard"
output_log=/var/log/hawser.log
error_log=/var/log/hawser.log
# respawn on crash, forever
respawn_delay=5
respawn_max=0

export PORT=${var.port}
export AGENT_NAME=${var.agent_name}

depend() {
    need docker
}

# docker's init script returns before dockerd has created its socket; on a
# cold boot hawser would start first, fail to load config and stay crashed
start_pre() {
    i=0
    while [ ! -S /var/run/docker.sock ] && [ $i -lt 60 ]; do
        sleep 1
        i=$((i + 1))
    done
    [ -S /var/run/docker.sock ] || {
        eerror "docker socket not found after 60s"
        return 1
    }
}
SCRIPT

  release_url = "https://github.com/finsys/hawser/releases/download/v${var.hawser_version}"
  tarball     = "hawser_${var.hawser_version}_linux_amd64.tar.gz"

  provision_script = <<-SCRIPT
set -e

have="$(/usr/local/bin/hawser --version 2>/dev/null | awk '{print $3}')" || true
if [ "$have" != "${var.hawser_version}" ]; then
  tmp="$(mktemp -d)"
  cd "$tmp"
  wget -q "${local.release_url}/${local.tarball}" "${local.release_url}/checksums.txt"
  grep " ${local.tarball}$" checksums.txt | sha256sum -c -
  tar xzf "${local.tarball}" hawser
  install -m 755 hawser /usr/local/bin/hawser.new
  cd /
  rm -rf "$tmp"
fi

# stop with whatever init script is currently installed before replacing it
rc-service hawser stop 2>/dev/null || true
[ -f /usr/local/bin/hawser.new ] && mv /usr/local/bin/hawser.new /usr/local/bin/hawser

echo ${base64encode(local.init_script)} | base64 -d > /etc/init.d/hawser
chmod 755 /etc/init.d/hawser
rc-update add hawser default
rc-service hawser start
SCRIPT
}

resource "terraform_data" "hawser" {
  triggers_replace = {
    node_ip = var.node_ip
    vm_id   = var.vm_id
    script  = sha256(local.provision_script)
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no shane@${var.node_ip} 'echo ${base64encode(local.provision_script)} | base64 -d | sudo pct exec ${var.vm_id} -- sh -s'"
  }
}
