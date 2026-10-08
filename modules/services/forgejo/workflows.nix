{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo;
  runuser = lib.getExe' pkgs.util-linux "runuser";
  psql = lib.getExe' config.services.postgresql.finalPackage "psql";
  metrics = "${config.homelab.metricsDir}/forgejo-workflows.prom";

  query = pkgs.writeText "forgejo-workflows.sql" ''
    select format(
      'homelab_forgejo_workflow_failed_run{repo="%s",workflow="%s",branch="%s"} %s',
      repo, workflow, branch, case when status = 2 then index else 0 end
    )
    from (
      select distinct on (r.id, a.workflow_id)
        r.owner_name || '/' || r.name as repo,
        a.workflow_id as workflow,
        r.default_branch as branch,
        a.status,
        a.index
      from action_run a
      join repository r on r.id = a.repo_id
      where a.ref = 'refs/heads/' || r.default_branch
        and a.event in ('push', 'schedule', 'workflow_dispatch')
        and a.status in (1, 2)
        and exists (select 1 from repo_unit u where u.repo_id = r.id and u.type = 10)
      order by r.id, a.workflow_id, a.id desc
    ) latest
  '';
in
{
  systemd.services.forgejo-workflow-metrics = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${runuser} -u ${cfg.user} -- ${psql} -d ${cfg.database.name} -At -f ${query} > ${metrics}.tmp
      mv ${metrics}.tmp ${metrics}
    '';
  };

  systemd.timers.forgejo-workflow-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/5";
  };
}
