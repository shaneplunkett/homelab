{ name, nodes, ... }:
{
  services.alloy.enable = true;
  environment.etc."alloy/config.alloy".source = ./config.alloy;
  systemd.services.alloy.environment = {
    ALLOY_HOST = name;
    LOKI_URL = "http://${nodes.monitoring.config.deployment.targetHost}:3100/loki/api/v1/push";
  };
}
