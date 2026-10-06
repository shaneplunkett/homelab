{
  config,
  lib,
  pkgs,
  nodes,
  ...
}:
let
  box = config.homelab.backup.storageBox;
  usageFile = "${config.homelab.metricsDir}/storagebox.prom";

  backedUp = lib.attrNames (lib.filterAttrs (_: node: node.config.homelab.backup.paths != [ ]) nodes);

  maxAge = {
    backup = 36 * 3600;
    prune = 9 * 86400;
    check = 9 * 86400;
  };

  freshness = lib.concatLists (
    lib.mapAttrsToList (task: seconds: [
      {
        alert = "BackupStale";
        expr = ''time() - homelab_backup_last_success_timestamp_seconds{task="${task}"} > ${toString seconds}'';
        labels = {
          severity = "warning";
          inherit task;
        };
        annotations.summary = "{{ $labels.host }}'s last successful restic ${task} was {{ $value | humanizeDuration }} ago";
      }
      {
        alert = "BackupMissing";
        expr = ''up{job="node", host=~"${lib.concatStringsSep "|" backedUp}"} unless on(host) homelab_backup_last_success_timestamp_seconds{task="${task}"}'';
        for = "${toString seconds}s";
        labels = {
          severity = "warning";
          inherit task;
        };
        annotations.summary = "{{ $labels.host }} has no successful restic ${task} on record";
      }
    ]) maxAge
  );
in
{
  homelab.secrets = [ "hetzner-api-token" ];

  systemd.services.storagebox-usage = {
    path = [
      pkgs.curl
      pkgs.jq
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -o pipefail
      curl -sSf -H "Authorization: Bearer $(< ${config.age.secrets.hetzner-api-token.path})" \
        https://api.hetzner.com/v1/storage_boxes/541366 \
        | jq -r '.storage_box | "homelab_storagebox_used_bytes \(.stats.size)\nhomelab_storagebox_size_bytes \(.storage_box_type.size)"' \
        > ${usageFile}.tmp
      mv ${usageFile}.tmp ${usageFile}
    '';
  };

  systemd.timers.storagebox-usage = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "storagebox";
      metrics_path = "/probe";
      params.module = [ "ssh_banner" ];
      static_configs = [ { targets = [ "${box}:23" ]; } ];
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
    (pkgs.writeText "backup.rules.json" (
      builtins.toJSON {
        groups = [
          {
            name = "backup";
            rules = freshness ++ [
              {
                alert = "StorageBoxUnreachable";
                expr = ''probe_success{job="storagebox"} == 0'';
                for = "15m";
                labels.severity = "warning";
                annotations.summary = "The Storage Box isn't answering SFTP, so no host can back up";
              }
              {
                alert = "StorageBoxFilling";
                expr = "homelab_storagebox_used_bytes / homelab_storagebox_size_bytes > 0.8";
                for = "1h";
                labels.severity = "warning";
                annotations.summary = "The Storage Box is {{ $value | humanizePercentage }} full";
              }
              {
                alert = "StorageBoxUsageStale";
                expr = ''time() - node_textfile_mtime_seconds{file=~".*storagebox.prom"} > 3 * 3600'';
                labels.severity = "warning";
                annotations.summary = "Storage Box usage hasn't updated from Hetzner's API in over 3 hours";
              }
            ];
          }
        ];
      }
    ))
  ];
}
