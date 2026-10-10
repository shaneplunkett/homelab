{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = config.age.secrets;
in
{
  homelab.secrets = [
    "grafana-admin-password"
    "grafana-secret-key"
    "grafana-oidc-client-secret"
  ];

  age.secrets.grafana-admin-password.owner = "grafana";
  age.secrets.grafana-secret-key.owner = "grafana";
  age.secrets.grafana-oidc-client-secret.owner = "grafana";

  homelab.routes.grafana = config.services.grafana.settings.server.http_port;

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
      "auth.generic_oauth" = {
        enabled = true;
        name = "Pocket ID";
        client_id = "grafana";
        client_secret = "$__file{${secrets.grafana-oidc-client-secret.path}}";
        scopes = "openid email profile groups";
        auth_url = "https://auth.shaneplunkett.com/authorize";
        token_url = "https://auth.shaneplunkett.com/api/oidc/token";
        api_url = "https://auth.shaneplunkett.com/api/oidc/userinfo";
        use_pkce = true;
        allow_sign_up = true;
        role_attribute_path = "contains(groups[*], 'grafana_admins') && 'Admin' || 'Viewer'";
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
      dashboards.settings.providers = [
        {
          name = "homelab";
          options.path = pkgs.writeTextDir "hosts.json" (
            builtins.toJSON (import ./dashboards/hosts.nix { inherit lib; })
          );
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];
}
