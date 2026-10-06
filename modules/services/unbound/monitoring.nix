{ lib, nodes, ... }:
let
  dnsHosts = lib.filterAttrs (_: node: node.config.services.blocky.enable) nodes;
in
{
  services = {
    unbound.localControlSocketPath = "/run/unbound/unbound.ctl";

    prometheus.exporters.unbound = {
      enable = true;
      openFirewall = true;
      unbound = {
        host = "unix:///run/unbound/unbound.ctl";
        ca = null;
        certificate = null;
        key = null;
      };
    };

    prometheus.scrapeConfigs = [
      {
        job_name = "unbound";
        static_configs = lib.mapAttrsToList (name: node: {
          targets = [ "${node.config.deployment.targetHost}:9167" ];
          labels.host = name;
        }) dnsHosts;
      }
    ];
  };
}
