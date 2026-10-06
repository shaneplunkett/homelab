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

      settings.theme = {
        background-color = "240 21 15";
        contrast-multiplier = 1.2;
        primary-color = "217 92 83";
        positive-color = "115 54 76";
        negative-color = "347 70 65";
      };

    };

    pages = [
      {
        name = "Home";
        columns = [
          {
            size = "full";
            widgets = [ { type = "calendar"; } ];
          }
        ];
      }
    ];

  };

  services.homepage-dashboard = {
    enable = false;
    openFirewall = true;
    allowedHosts = "dashboard.shaneplunkett.com,192.168.1.152:8082";
    environmentFiles = [ secrets.proxmox-token.path ];
    services = [
      {
        "Infrastructure" = [
          {
            "PVE" = {
              href = "https://proxmox.shaneplunkett.com";
              description = "Proxmox";
              icon = "proxmox.png";
              widget = {
                type = "proxmox";
                url = "https://proxmox.shaneplunkett.com";
                username = "homepage@pve!dashboard";
                password = "{{HOMEPAGE_VAR_PROXMOX_TOKEN}}";
              };
            };
          }
        ];

      }
    ];
  };
}
