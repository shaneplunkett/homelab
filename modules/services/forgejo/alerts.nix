{ pkgs, ... }:
let
  unitDown = alert: unit: what: {
    inherit alert;
    expr = ''node_systemd_unit_state{name="${unit}", state="active"} == 0'';
    for = "5m";
    labels.severity = "critical";
    annotations = {
      summary = "${what} isn't running on {{ $labels.host }}";
      condition = "${unit} inactive for 5m";
      check = "ssh root@{{ $labels.host }} journalctl -u ${unit} -n 50";
    };
  };
in
{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "forgejo.rules.json" (
      builtins.toJSON {
        groups = [
          {
            name = "forgejo";
            rules = [
              (unitDown "ForgejoDown" "forgejo.service" "Forgejo")
              (unitDown "ForgejoPostgresDown" "postgresql.service" "Forgejo's PostgreSQL")
            ];
          }
        ];
      }
    ))
  ];
}
