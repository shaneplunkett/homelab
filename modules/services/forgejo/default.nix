{
  config,
  lib,
  pkgs,
  nodes,
  ...
}:
let
  cfg = config.services.forgejo;
  secrets = config.age.secrets;
  exe = lib.getExe cfg.package;
  runuser = lib.getExe' pkgs.util-linux "runuser";
  postgres = config.services.postgresql.finalPackage;
  dumps = "/var/backup/forgejo";
  dump = "${dumps}/forgejo.dump";
  source = "pocket-id";

  env = {
    USER = cfg.user;
    HOME = cfg.stateDir;
    FORGEJO_WORK_DIR = cfg.stateDir;
    FORGEJO_CUSTOM = cfg.customDir;
  };

  admin = pkgs.writeShellScriptBin "forgejo-admin" ''
    exec ${runuser} -u ${cfg.user} -- ${lib.getExe' pkgs.coreutils "env"} \
      ${lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "${name}=${value}") env)} \
      ${exe} admin "$@"
  '';

  oidc = pkgs.writeShellScript "forgejo-oidc" ''
    secret="$(< "$CREDENTIALS_DIRECTORY/secret")"
    id="$(${exe} admin auth list | ${lib.getExe pkgs.gawk} '$2 == "${source}" { print $1 }')"
    set -- --name ${source} --provider openidConnect --key forgejo --secret "$secret" \
      --auto-discover-url https://auth.shaneplunkett.com/.well-known/openid-configuration \
      --scopes email --scopes profile --scopes groups \
      --group-claim-name groups --admin-group forgejo_admins --skip-local-2fa
    if [ -n "$id" ]; then
      exec ${exe} admin auth update-oauth --id "$id" "$@"
    fi
    exec ${exe} admin auth add-oauth "$@"
  '';
in
{
  homelab = {
    secrets = [ "forgejo-oidc-client-secret" ];

    routes.git = cfg.settings.server.HTTP_PORT;

    monitoring.units = [
      "forgejo.service"
      "postgresql.service"
    ];

    backup = {
      paths = [
        cfg.stateDir
        dumps
      ];
      prepare = ''
        ${runuser} -u postgres -- \
          ${postgres}/bin/pg_dump -Fc -Z0 -d ${cfg.database.name} -f ${dump}.tmp
        mv ${dump}.tmp ${dump}
      '';
    };
  };

  services.forgejo = {
    enable = true;
    database.type = "postgres";
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.shaneplunkett.com";
        ROOT_URL = "https://git.shaneplunkett.com/";
        SSH_DOMAIN = "forge";
      };
      security.REVERSE_PROXY_TRUSTED_PROXIES = nodes.ingress.config.homelab.lanAddress;
      session.COOKIE_SECURE = true;
      service = {
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        SHOW_REGISTRATION_BUTTON = false;
        DEFAULT_KEEP_EMAIL_PRIVATE = true;
      };
      openid.ENABLE_OPENID_SIGNIN = false;
      oauth2_client = {
        ENABLE_AUTO_REGISTRATION = true;
        USERNAME = "preferred_username";
      };
      actions.ENABLED = true;
    };
  };

  systemd.services.forgejo-oidc = {
    after = [ "forgejo.service" ];
    requires = [ "forgejo.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = env;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = cfg.user;
      LoadCredential = "secret:${secrets.forgejo-oidc-client-secret.path}";
      ExecStart = oidc;
    };
  };

  systemd.tmpfiles.rules = [ "d ${dumps} 0700 postgres postgres -" ];

  environment.systemPackages = [ admin ];

  networking.firewall.allowedTCPPorts = [ cfg.settings.server.HTTP_PORT ];
}
