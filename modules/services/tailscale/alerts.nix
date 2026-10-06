{ pkgs, ... }:
{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "tailscale.rules.json" (
      builtins.toJSON {
        groups = [
          {
            name = "tailscale";
            rules = [
              {
                alert = "TailscaleDown";
                expr = ''node_systemd_unit_state{name="tailscaled.service", state="active"} == 0'';
                for = "5m";
                labels.severity = "warning";
                annotations.summary = "tailscaled isn't running on {{ $labels.host }}";
              }
            ];
          }
        ];
      }
    ))
  ];
}
