{ config, ... }:
let
  secrets = config.age.secrets;
in
{
  homelab.secrets = [
    "discord-webhook"
    "proxmox-token"
  ];
  systemd.services.gatus.serviceConfig.EnvironmentFile = [ secrets.proxmox-token.path ];

  services.gatus = {
    enable = true;
    openFirewall = true;
    environmentFile = secrets.discord-webhook.path;

    settings = {
      web.port = 8082;

      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };

      alerting.discord.webhook-url = "\${DISCORD_WEBHOOK_URL}";

      endpoints = [
        {
          name = "PVE";
          group = "Infrastructure";
          url = "https://proxmox.shaneplunkett.com/api2/json/nodes/pve/status";
          headers.Authorization = "PVEAPIToken=homepage@pve!dashboard=\${HOMEPAGE_VAR_PROXMOX_TOKEN}";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "discord";
              send-on-resolved = true;
            }
          ];
        }
      ];
    };
  };
}
