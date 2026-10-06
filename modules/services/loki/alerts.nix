{ pkgs, ... }:
let
  rules = pkgs.writeTextDir "fake/oom.yaml" (
    builtins.toJSON {
      groups = [
        {
          name = "logs";
          rules = [
            {
              alert = "OomKill";
              expr = ''sum by (host, oom_unit) (count_over_time({unit="init.scope"} |= "OOM killer" | regexp "^(?P<oom_unit>[^:]+): " | oom_unit !~ ".+\\.slice" [5m])) > 0'';
              labels.severity = "warning";
              annotations.summary = "The OOM killer hit {{ $labels.oom_unit }} on {{ $labels.host }}";
            }
          ];
        }
      ];
    }
  );
in
{
  services.loki.configuration.ruler = {
    alertmanager_url = "http://localhost:9093";
    external_url = "https://grafana.shaneplunkett.com";
    enable_api = true;
    rule_path = "/var/lib/loki/rules-temp";
    storage = {
      type = "local";
      local.directory = rules;
    };
  };
}
