{
  lib,
  nodes,
  options,
}:
label: threshold: rule:
let
  default = options.homelab.monitoring.thresholds.${threshold}.default;
  valueOf = name: nodes.${name}.config.homelab.monitoring.thresholds.${threshold};
  overridden = lib.filter (name: valueOf name != default) (lib.attrNames nodes);
  matching = op: names: ''${label}${op}"${lib.concatStringsSep "|" names}"'';
  percent = value: "${toString (builtins.floor (value * 100 + 0.5))}%";
in
[
  (rule {
    value = default;
    percent = percent default;
    matcher = matching "!~" overridden;
  })
]
++ lib.mapAttrsToList (
  _: names:
  rule {
    value = valueOf (lib.head names);
    percent = percent (valueOf (lib.head names));
    matcher = matching "=~" names;
  }
) (lib.groupBy (name: toString (valueOf name)) overridden)
