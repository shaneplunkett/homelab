{
  imports = [
    ../services/prometheus
    ../services/pve-exporter
    ../services/alertmanager
    ../services/gatus/alerts.nix
    ../services/grafana
    ../services/loki
    ../services/blocky/monitoring.nix
  ];
}
