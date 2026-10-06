_: {

  services.prometheus.rules = [
    (builtins.toJSON {
      groups = [
        {
          name = "pve";
          rules = [
            {
              alert = "LxcDiskFilling";
              expr = ''(pve_disk_usage_bytes / pve_disk_size_bytes) * on(id) group_left(name, node) pve_guest_info{type="lxc"} > 0.85'';
              for = "10m";
              labels.severity = "warning";
              annotations.summary = "{{ $labels.name }} on {{ $labels.node }} is {{ $value | humanizePercentage }} full";
            }
          ];
        }
      ];
    })
  ];
}
