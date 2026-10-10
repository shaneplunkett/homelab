{ lib }:
let
  datasource = {
    type = "prometheus";
    uid = "prometheus";
  };

  physicalNics = ''device=~"eth.*|en.*"'';
  realFilesystems = ''fstype=~"ext4|xfs|btrfs|zfs|vfat|nfs4",mountpoint!="/nix/store"'';

  cpuUsed =
    window:
    ''100 * (1 - avg by (host) (rate(node_cpu_seconds_total{job="node",mode="idle"}[${window}])))'';
  memoryUsed = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)";
  rootUsed = ''100 * (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})'';
  traffic =
    direction: selector:
    "rate(node_network_${direction}_bytes_total{${selector},${physicalNics}}[$__rate_interval])";

  at = x: y: w: h: { inherit x y w h; };

  query = legendFormat: expr: { inherit datasource expr legendFormat; };

  percent = {
    unit = "percent";
    min = 0;
    max = 100;
    decimals = 0;
    thresholds = {
      mode = "absolute";
      steps = [
        {
          color = "green";
          value = null;
        }
        {
          color = "orange";
          value = 75;
        }
        {
          color = "red";
          value = 90;
        }
      ];
    };
  };

  panel =
    {
      type,
      title,
      gridPos,
      targets,
      defaults,
      options,
    }:
    {
      inherit
        type
        title
        gridPos
        datasource
        options
        ;
      targets = lib.imap0 (i: target: target // { refId = builtins.substring i 1 "ABCDEFGH"; }) targets;
      fieldConfig = {
        inherit defaults;
        overrides = [ ];
      };
    };

  row = title: y: {
    type = "row";
    inherit title;
    gridPos = at 0 y 24 1;
    collapsed = false;
    panels = [ ];
  };

  usageNow =
    title: gridPos: legendFormat: expr:
    panel {
      type = "bargauge";
      inherit title gridPos;
      targets = [
        (
          query legendFormat "sort_desc(${expr})"
          // {
            instant = true;
            range = false;
          }
        )
      ];
      defaults = percent;
      options = {
        orientation = "horizontal";
        displayMode = "basic";
        namePlacement = "left";
        showUnfilled = true;
        reduceOptions = {
          calcs = [ "lastNotNull" ];
          fields = "";
          values = false;
        };
      };
    };

  overTime =
    {
      title,
      gridPos,
      targets,
      defaults ? percent,
      stacked ? false,
    }:
    panel {
      type = "timeseries";
      inherit title gridPos targets;
      defaults = defaults // {
        custom = {
          lineWidth = 1;
          showPoints = "never";
          fillOpacity = if stacked then 40 else 0;
          stacking = {
            mode = if stacked then "normal" else "none";
            group = "A";
          };
        };
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
    };

  everyHost = ''job="node"'';
  host = ''host="$host"'';
in
{
  uid = "hosts";
  title = "Host health";
  tags = [ "homelab" ];
  timezone = "browser";
  refresh = "1m";
  schemaVersion = 41;
  time = {
    from = "now-24h";
    to = "now";
  };

  templating.list = [
    {
      name = "host";
      label = "Host";
      type = "query";
      inherit datasource;
      query = {
        qryType = 1;
        query = ''label_values(up{job="node"}, host)'';
        refId = "hosts";
      };
      definition = ''label_values(up{job="node"}, host)'';
      refresh = 1;
      sort = 1;
    }
  ];

  panels = lib.imap1 (id: panel: panel // { inherit id; }) [
    (row "All hosts" 0)
    (usageNow "CPU now" (at 0 1 8 12) "{{host}}" (cpuUsed "5m"))
    (usageNow "Memory now" (at 8 1 8 12) "{{host}}" memoryUsed)
    (usageNow "Root disk now" (at 16 1 8 12) "{{host}}" rootUsed)
    (overTime {
      title = "CPU";
      gridPos = at 0 13 12 9;
      targets = [ (query "{{host}}" (cpuUsed "$__rate_interval")) ];
    })
    (overTime {
      title = "Memory";
      gridPos = at 12 13 12 9;
      targets = [ (query "{{host}}" memoryUsed) ];
    })
    (overTime {
      title = "Root disk";
      gridPos = at 0 22 12 9;
      targets = [ (query "{{host}}" rootUsed) ];
    })
    (overTime {
      title = "Network";
      gridPos = at 12 22 12 9;
      defaults.unit = "Bps";
      targets = [
        (query "{{host}}" "sum by (host) (${traffic "receive" everyHost} + ${traffic "transmit" everyHost})")
      ];
    })

    (row "$host" 31)
    (overTime {
      title = "CPU by mode";
      gridPos = at 0 32 12 9;
      stacked = true;
      defaults = removeAttrs percent [ "max" ];
      targets = [
        (query "{{mode}}" ''100 * avg by (mode) (rate(node_cpu_seconds_total{${host},mode!="idle"}[$__rate_interval]))'')
      ];
    })
    (overTime {
      title = "Memory";
      gridPos = at 12 32 12 9;
      stacked = true;
      defaults.unit = "bytes";
      targets = [
        (query "Used" "node_memory_MemTotal_bytes{${host}} - node_memory_MemAvailable_bytes{${host}}")
        (query "Available" "node_memory_MemAvailable_bytes{${host}}")
      ];
    })
    (usageNow "Filesystems" (at 0 41 12 9) "{{mountpoint}}"
      "100 * (1 - node_filesystem_avail_bytes{${host},${realFilesystems}} / node_filesystem_size_bytes{${host},${realFilesystems}})"
    )
    (overTime {
      title = "Network";
      gridPos = at 12 41 12 9;
      defaults.unit = "Bps";
      targets = [
        (query "{{device}} in" "sum by (device) (${traffic "receive" host})")
        (query "{{device}} out" "-sum by (device) (${traffic "transmit" host})")
      ];
    })
  ];
}
