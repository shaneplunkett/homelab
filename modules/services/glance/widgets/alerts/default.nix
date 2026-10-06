{ nodes }:
{
  type = "custom-api";
  title = "Alerts";
  cache = "1m";
  url = "http://${nodes.monitoring.config.homelab.lanAddress}:9093/api/v2/alerts";
  parameters = {
    active = "true";
    silenced = "false";
    inhibited = "false";
  };
  template = builtins.readFile ./template.html;
}
