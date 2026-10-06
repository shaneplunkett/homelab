{ config, ... }:
let
  secrets = config.age.secrets;
in
{
  homelab.secrets = [ "gatus-discord" ];
  systemd.services.gatus.serviceConfig.EnvironmentFile = [ secrets.proxmox-token.path ];

  services.gatus = {
    enable = true;
    openFirewall = true;
    environmentFile = secrets.gatus-discord.path;

    settings = {
      web.port = 8082;

      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };

      alerting.discord.webhook-url = "\${GATUS_DISCORD_URL}";

      endpoints = [
        {
          name = "PVE";
          group = "Infrastructure";
          url = "https://proxmox.shaneplunkett.com/api2/json/nodes/pve/status";
          headers.Authorization = "PVEAPIToken=homepage@pve!dashboard=\${HOMEPAGE_VAR_PROXMOX_TOKEN}";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
            "[BODY].data.cpu < 0.9"

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
