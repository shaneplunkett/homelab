{ config, ... }:
let
  secrets = config.age.secrets;
in
{
  homelab.secrets = [
    "grafana-admin-password"
    "grafana-secret-key"
  ];

  age.secrets.grafana-admin-password.owner = "grafana";
  age.secrets.grafana-secret-key.owner = "grafana";

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        root_url = "https://grafana.shaneplunkett.com";
      };
      security = {
        admin_password = "$__file{${secrets.grafana-admin-password.path}}";
        secret_key = "$__file{${secrets.grafana-secret-key.path}}";
      };
      analytics.reporting_enabled = false;
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];
}
