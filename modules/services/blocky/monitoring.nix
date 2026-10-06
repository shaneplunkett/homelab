{
  pkgs,
  lib,
  nodes,
  ...
}:
let
  dnsHosts = lib.filterAttrs (_: node: node.config.services.blocky.enable) nodes;
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "blocky";
      static_configs = lib.mapAttrsToList (name: node: {
        targets = [ "${node.config.homelab.lanAddress}:4000" ];
        labels.host = name;
      }) dnsHosts;
    }

    {
      job_name = "dns";
      metrics_path = "/probe";
      params = {
        module = [ "dns" ];
      };
      static_configs = lib.mapAttrsToList (name: node: {
        targets = [ "${node.config.homelab.lanAddress}" ];
        labels.host = name;
      }) dnsHosts;
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "localhost:9115";
        }
      ];
    }
  ];
  services.prometheus.ruleFiles = [
    (pkgs.writeText "blocky.rules.json" (
      builtins.toJSON {
        groups = [
          {
            name = "dns";
            rules = [
              {
                alert = "DnsNotAnswering";
                expr = ''probe_success{job="dns"} == 0'';
                for = "3m";
                labels.severity = "critical";
                annotations.summary = "{{ $labels.host }} isnt answering DNS";
              }
            ];
          }
        ];
      }
    ))
  ];
}
