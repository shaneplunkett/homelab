#!/bin/sh
set -eu

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q --no-install-recommends \
  prometheus-node-exporter \
  prometheus-node-exporter-collectors \
  nvme-cli
systemctl enable --now prometheus-node-exporter.service prometheus-node-exporter-nvme.timer
