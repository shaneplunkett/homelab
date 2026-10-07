{
  config,
  lib,
  pkgs,
  vex-brain,
  ...
}:
let
  user = "vex_brain";
  python = pkgs.python312;
  venv = "/var/lib/vex-brain/venv";
  dumps = "/var/backup/vex-brain";
  archive = "/var/lib/vex-brain-archive";
  dump = "${dumps}/vex_brain.dump";
  postgres = config.services.postgresql.finalPackage;

  syncVenv = pkgs.writeShellScript "vex-brain-venv" ''
    grep -qxF "home = ${python}/bin" ${venv}/pyvenv.cfg 2>/dev/null || rm -rf ${venv}
    exec ${lib.getExe pkgs.uv} sync --frozen --no-dev --no-install-project --python ${lib.getExe python}
  '';

  restore = pkgs.writeShellApplication {
    name = "vex-brain-restore";
    runtimeInputs = [
      postgres
      pkgs.util-linux
    ];
    text = ''
      dump=$(realpath "''${1:?usage: vex-brain-restore <pg_dump -Fc file>}")
      as_postgres() { runuser -u postgres -- "$@"; }

      as_postgres pg_restore --list "$dump" | grep -v ' EXTENSION ' > /tmp/vex-brain-restore.list
      systemctl stop vex-brain
      as_postgres dropdb --if-exists ${user}
      as_postgres createdb -O ${user} ${user}
      as_postgres psql -d ${user} -c 'CREATE EXTENSION vector' -c 'CREATE EXTENSION pg_trgm'
      as_postgres pg_restore --no-owner --role=${user} --exit-on-error \
        -L /tmp/vex-brain-restore.list -d ${user} "$dump"
      rm /tmp/vex-brain-restore.list
      systemctl start vex-brain
    '';
  };

  stamp = pkgs.writeShellScript "stamp-restore-drill" ''
    file=${config.homelab.metricsDir}/vex-brain-restore-drill.prom
    echo "vex_brain_restore_drill_last_success_timestamp_seconds $(date +%s)" > "$file.tmp"
    mv "$file.tmp" "$file"
  '';
in
{
  homelab = {
    secrets = [ "vex-brain" ];

    monitoring.units = [
      "vex-brain.service"
      "postgresql.service"
    ];

    backup = {
      paths = [
        dumps
        archive
      ];
      prepare = ''
        ${lib.getExe' pkgs.util-linux "runuser"} -u postgres -- \
          ${postgres}/bin/pg_dump -Fc -Z0 -d ${user} -f ${dump}.tmp
        mv ${dump}.tmp ${dump}
      '';
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    extensions = ps: [ ps.pgvector ];
    ensureDatabases = [ user ];
    ensureUsers = [
      {
        name = user;
        ensureDBOwnership = true;
      }
    ];
    settings = {
      shared_buffers = "1GB";
      effective_cache_size = "4GB";
      maintenance_work_mem = "512MB";
    };
  };

  systemd.services.postgresql-setup.script = lib.mkAfter ''
    psql -d ${user} -c 'CREATE EXTENSION IF NOT EXISTS vector' -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm'
  '';

  users.users.${user} = {
    isSystemUser = true;
    group = user;
  };
  users.groups.${user} = { };

  systemd.services.vex-brain = {
    description = "Vex brain";
    after = [
      "network-online.target"
      "postgresql.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      VEX_BRAIN_DATABASE_URL = "postgresql://${user}@/${user}?host=/run/postgresql";
      VEX_BRAIN_HOST = "127.0.0.1";
      VEX_BRAIN_PORT = "8000";
      VEX_BRAIN_PIPELINE_MODE = "agent";
      VEX_BRAIN_LOG_LEVEL = "INFO";
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";
      UV_PROJECT_ENVIRONMENT = venv;
      UV_CACHE_DIR = "/var/cache/vex-brain";
      UV_PYTHON_DOWNLOADS = "never";
      UV_NO_MANAGED_PYTHON = "1";
    };

    serviceConfig = {
      User = user;
      Group = user;
      WorkingDirectory = vex-brain;
      EnvironmentFile = config.age.secrets.vex-brain.path;
      StateDirectory = "vex-brain";
      CacheDirectory = "vex-brain";
      ExecStartPre = syncVenv;
      ExecStart = "${venv}/bin/python -m app.main";
      Restart = "on-failure";
      RestartSec = "10s";
      TimeoutStartSec = "10min";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  environment.systemPackages = [ restore ];

  systemd.tmpfiles.rules = [
    "d ${dumps} 0700 postgres postgres -"
    "d ${archive} 0700 root root -"
  ];

  systemd.services.vex-brain-restore-drill = {
    description = "Restore the latest brain dump into a scratch database";
    after = [ "postgresql.target" ];
    requires = [ "postgresql.target" ];
    path = [ postgres ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStartPost = "+${stamp}";
    };
    script = ''
      set -euo pipefail
      dropdb --if-exists vex_brain_drill
      createdb vex_brain_drill
      trap 'dropdb --if-exists vex_brain_drill' EXIT
      pg_restore --no-owner --exit-on-error -d vex_brain_drill ${dump}
      conversations=$(psql -Atd vex_brain_drill -c 'SELECT count(*) FROM conversations')
      entities=$(psql -Atd vex_brain_drill -c 'SELECT count(*) FROM entities')
      echo "Restored $conversations conversations and $entities entities"
      [ "$conversations" -gt 0 ] && [ "$entities" -gt 0 ]
    '';
    startAt = "Sat 05:30";
  };
}
