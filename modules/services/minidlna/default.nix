{ config, ... }:
let
  cfg = config.services.minidlna;
in
{
  homelab.monitoring.units = [ "minidlna.service" ];

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "Programs";
      media_dir = [ "/mnt/programs" ];
    };
  };

  systemd.services.minidlna-rescan = {
    startAt = "04:00";
    serviceConfig.Type = "oneshot";
    script = ''
      systemctl stop minidlna
      rm -f ${cfg.settings.db_dir}/files.db
      systemctl start minidlna
    '';
  };
}
