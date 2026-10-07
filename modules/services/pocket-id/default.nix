{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pocket-id;
  secrets = config.age.secrets;
  sqlite3 = lib.getExe' pkgs.sqlite "sqlite3";
  db = "${cfg.dataDir}/data/pocket-id.db";
  dumps = "${cfg.dataDir}/dumps";

  recover = pkgs.writeShellScriptBin "pocket-id-recover" ''
    cd ${cfg.dataDir}
    export APP_URL=${cfg.settings.APP_URL}
    ENCRYPTION_KEY="$(cat ${secrets.pocket-id-encryption-key.path})"
    export ENCRYPTION_KEY
    exec ${lib.getExe' pkgs.util-linux "runuser"} -u ${cfg.user} -- ${lib.getExe cfg.package} one-time-access-token "$@"
  '';
in
{
  homelab.secrets = [ "pocket-id-encryption-key" ];

  homelab.routes.auth = cfg.settings.PORT;

  services.pocket-id = {
    enable = true;
    credentials.ENCRYPTION_KEY = secrets.pocket-id-encryption-key.path;
    settings = {
      APP_URL = "https://auth.shaneplunkett.com";
      PORT = 1411;
      TRUST_PROXY = true;
      ANALYTICS_DISABLED = true;
    };
  };

  homelab.backup = {
    paths = [ cfg.dataDir ];
    exclude = [ "${db}*" ];
    prepare = ''
      if [ -e ${db} ]; then
        install -d -m 0700 ${dumps}
        ${sqlite3} ${db} ".backup '${dumps}/pocket-id.db'"
      fi
    '';
  };

  environment.systemPackages = [ recover ];

  networking.firewall.allowedTCPPorts = [ cfg.settings.PORT ];
}
