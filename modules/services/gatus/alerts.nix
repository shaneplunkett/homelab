{ pkgs, ... }: {
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "gatus";
        static_configs = [ { targets = [ "192.168.1.152:8082" ]; } ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "gatus.rules.json" (
        builtins.toJSON {
          groups = [
            {
              name = "gatus";
              rules = [
                {
                  alert = "EndpointDown";
                  expr = "gatus_results_endpoint_success == 0";
                  for = "3m";
                  labels.severity = "critical";
                  annotations.summary = "{{ $labels.group }}/{{ $labels.name }} is failing its Gatus checks";
                }
                {
                  alert = "GatusDown";
                  expr = ''up{job="gatus"} == 0'';
                  for = "5m";
                  labels.severity = "critical";
                  annotations.summary = "Gatus on the dashboard host isn't answering, so PVE or the dashboard box may be down";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
