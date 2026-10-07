{
  config,
  lib,
  pkgs,
  ...
}:
{
  homelab = {
    secrets = [ "cloudflared-brain" ];
    monitoring.units = [ "cloudflared.service" ];
  };

  networking.hosts."127.0.0.1" = [ "vex-brain" ];

  systemd.services.cloudflared = {
    description = "Cloudflare tunnel for the brain";
    after = [
      "network-online.target"
      "vex-brain.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.cloudflared} tunnel --no-autoupdate run";
      EnvironmentFile = config.age.secrets.cloudflared-brain.path;
      DynamicUser = true;
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
