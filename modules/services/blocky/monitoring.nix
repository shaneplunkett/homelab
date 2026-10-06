{ lib, nodes, ... }:
let
  dnsHosts = lib.filterAttrs (_: node: node.config.services.blocky.enable) nodes;
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "blocky";
      static_configs = lib.mapAttrsToList (name: node: {
        targets = [ "${node.config.deployment.targetHost}:4000" ];
        labels.host = name;
      }) dnsHosts;
    }
  ];
}
