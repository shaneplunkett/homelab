{
  config,
  lib,
  nodes,
  ...
}:
let
  secrets = config.age.secrets;
  domain = "shaneplunkett.com";

  externalRoutes = {
    unraid = "http://192.168.1.132:80";
    proxmox = "https://192.168.1.169:8006";
    unifi = "https://192.168.1.1:443";
    coffee = "http://192.168.20.29:80";
    docker = "http://192.168.1.158:3000";
  };

  hiveRoutes = lib.concatMapAttrs (
    _: node:
    lib.mapAttrs (
      _: port: "http://${node.config.homelab.lanAddress}:${toString port}"
    ) node.config.homelab.routes
  ) nodes;

  routeNames =
    lib.attrNames externalRoutes
    ++ lib.concatMap (node: lib.attrNames node.config.homelab.routes) (lib.attrValues nodes);

  routes = externalRoutes // hiveRoutes;
in
{
  homelab.secrets = [ "cloudflare-dns" ];

  assertions = [
    {
      assertion = lib.allUnique routeNames;
      message = "Two routes claim the same subdomain: ${toString routeNames}";
    }
  ];

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

    virtualHosts =
      lib.mapAttrs' (
        name: upstream:
        lib.nameValuePair "${name}.${domain}" {
          useACMEHost = domain;
          forceSSL = true;
          locations."/" = {
            proxyPass = upstream;
            proxyWebsockets = true;
          };
        }
      ) routes
      // {
        "_" = {
          default = true;
          useACMEHost = domain;
          forceSSL = true;
          locations."/".return = "404";
        };
      };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
