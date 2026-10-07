{
  imports = [
    ../services/prometheus
    ../services/pve-exporter
    ../services/alertmanager
    ../services/gatus/alerts.nix
    ../services/grafana
    ../services/loki
    ../services/blocky/monitoring.nix
    ../services/unbound/monitoring.nix
    ../services/blackbox
    ../services/tailscale/alerts.nix
    ../services/backup/monitoring.nix
    ../services/vex-brain/alerts.nix
  ];
}
