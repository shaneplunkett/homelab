{ config, lib, ... }:
let
  secrets = config.age.secrets;
  domain = "shaneplunkett.com";

  routes = {
    unraid = "http://192.168.1.132:80";
    proxmox = "https://192.168.1.169:8006";
    unifi = "https://192.168.1.1:443";
    coffee = "http://192.168.20.29:80";

    # arr
    overseer = "http://192.168.1.90:5055";
    prowlarr = "http://192.168.1.90:9696";
    nzb = "http://192.168.1.90:8080";
    deluge = "http://192.168.1.90:8112";
    radarr = "http://192.168.1.90:7878";
    sonarr = "http://192.168.1.90:8989";
    sonarranime = "http://192.168.1.90:8990";

    # Hive
    dashboard = "http://192.168.1.152:8080";
    status = "http://192.168.1.152:8082";
    grafana = "http://192.168.1.78:3000";
    prometheus = "http://192.168.1.78:9090";
  };
in
{
  homelab.secrets = [ "cloudflare-dns" ];

  security.acme = {
    acceptTerms = true;
    certs.${domain} = {
      domain = "*.${domain}";
      extraDomainNames = [ "*.shaneplunkett.dev" ];
      dnsProvider = "cloudflare";
      environmentFile = secrets.cloudflare-dns.path;
      dnsResolver = "1.1.1.1:53";
      group = config.services.nginx.group;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    clientMaxBodySize = "0";

    virtualHosts = lib.mapAttrs' (
      name: upstream:
      lib.nameValuePair "${name}.${domain}" {
        useACMEHost = domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = upstream;
          proxyWebsockets = true;
        };
      }
    ) routes;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
