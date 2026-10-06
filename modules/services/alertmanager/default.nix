{ config, ... }:
let
  secrets = config.age.secrets;
in
{
  homelab.secrets = [ "discord-webhook" ];

  services.prometheus.alertmanager = {
    enable = true;
    openFirewall = true;
    environmentFile = secrets.discord-webhook.path;
    checkConfig = false;
    configuration = {
      route = {
        receiver = "discord";
        group_by = [
          "alertname"
          "name"
        ];
        repeat_interval = "24h";
      };
      receivers = [
        {
          name = "discord";
          discord_configs = [ { webhook_url = "\${DISCORD_WEBHOOK_URL}"; } ];
        }
      ];
    };
  };

  services.prometheus.alertmanagers = [
    { static_configs = [ { targets = [ "localhost:9093" ]; } ]; }
  ];

}
