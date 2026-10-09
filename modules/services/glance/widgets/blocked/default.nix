{ nodes }:
{
  type = "custom-api";
  title = "Recently blocked";
  cache = "1m";
  url = "http://${nodes.monitoring.config.homelab.lanAddress}:3100/loki/api/v1/query_range";
  parameters = {
    query = ''{unit="blocky.service"} |= "response_type=BLOCKED" | regexp `question_name=(?P<domain>\S+?)\.? .*response_reason=BLOCKED (?:CNAME )?\((?P<list>[^:]+): (?P<rule>[^)]+)\)` | keep domain, list, rule'';
    since = "1h";
    limit = "5000";
  };
  template = builtins.readFile ./template.html;
}
