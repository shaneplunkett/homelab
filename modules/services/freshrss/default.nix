{
  config,
  lib,
  pkgs,
  nodes,
  ...
}:
let
  cfg = config.services.freshrss;
  shane = "4057ed4b-d22c-403b-804c-323c1b199b36";
  ingress = lib.escapeRegex nodes.ingress.config.homelab.lanAddress;
  users = "${cfg.dataDir}/users";
  sqlite = lib.getExe' pkgs.sqlite "sqlite3";

  af-readability = pkgs.freshrss-extensions.buildFreshRssExtension {
    FreshRssExtUniqueId = "Af_Readability";
    pname = "af-readability";
    version = "0.5-unstable-2026-08-11";
    src = pkgs.fetchFromGitHub {
      owner = "Niehztog";
      repo = "freshrss-af-readability";
      rev = "7e0dc8fd82d5f13863e5121cbe0f7b1f2d194fd9";
      hash = "sha256-lfUZOwLqAzoiUyqSLIe+Q7mTq1clDsm3WhKMI5G8nGA=";
    };
  };
in
{
  homelab = {
    routes.rss = 80;

    backup = {
      paths = [ cfg.dataDir ];
      exclude = [
        "${users}/*/db.sqlite*"
        "${cfg.dataDir}/cache"
      ];
      prepare = ''
        for db in ${users}/*/db.sqlite; do
          ${sqlite} "$db" ".backup $(dirname "$db")/backup.sqlite"
        done
      '';
    };

    monitoring.units = [
      "nginx.service"
      "phpfpm-freshrss.service"
      "freshrss-updater.service"
    ];
  };

  services.freshrss = {
    enable = true;
    baseUrl = "https://rss.shaneplunkett.com";
    defaultUser = shane;
    authType = "http_auth";
    api.enable = true;
    extensions = [
      pkgs.freshrss-extensions.youtube
      af-readability
    ];
  };

  services.nginx = {
    appendHttpConfig = ''
      map "$remote_addr:$uri" $freshrss_user {
        "~^${ingress}:/api/" "";
        "~^${ingress}:" $http_x_user;
        default "";
      }
    '';

    virtualHosts.${cfg.virtualHost} = {
      default = true;
      locations."~ ^.+?\\.php(/.*)?$".extraConfig = ''
        fastcgi_param REMOTE_USER $freshrss_user if_not_empty;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
