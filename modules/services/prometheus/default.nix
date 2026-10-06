{ config, ... }:
{
  imports = [ ./node.nix ];

  homelab.routes.prometheus = config.services.prometheus.port;

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prometheus.shaneplunkett.com";
    retentionTime = "30d";
    extraFlags = [ "--storage.tsdb.retention.size=12GB" ];
  };
  networking.firewall.allowedTCPPorts = [ 9090 ];
}
