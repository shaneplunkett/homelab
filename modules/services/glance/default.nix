{ config, ... }:

let
  secrets = config.age.secrets;
in
{
  homelab.secrets = [ "proxmox-token" ];

  services.glance = {
    enable = true;
    openFirewall = true;
    environmentFile = secrets.proxmox-token.path;
    settings = {
      server = {
        host = "0.0.0.0";
        port = 8080;

      };

      theme = {
        background-color = "240 21 15";
        contrast-multiplier = 1.2;
        primary-color = "232 97 85";
        positive-color = "115 54 76";
        negative-color = "347 70 65";
      };

      pages = [
        {
          name = "Home";
          columns = [
            {
              size = "full";
              widgets = [
                { type = "calendar"; }
                (import ./widgets/proxmox-ve-stats)
              ];
            }
          ];
        }
      ];
    };

  };

}
