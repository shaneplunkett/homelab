{
  lib,
  nodes,
  group,
}:
let
  media = [
    "overseer"
    "prowlarr"
    "nzb"
    "deluge"
    "radarr"
    "sonarr"
    "sonarranime"
  ];

  overrides = {
    unifi.title = "UniFi";
    coffee = {
      title = "Coffee";
      icon = "mdi:coffee";
    };
    overseer = {
      title = "Overseerr";
      icon = "di:overseerr";
    };
    nzb = {
      title = "SABnzbd";
      icon = "di:sabnzbd";
    };
    sonarranime = {
      title = "Sonarr Anime";
      icon = "di:sonarr";
    };
    docker = {
      title = "Dockhand";
      icon = "di:dockhand.png";
    };
    dashboard.icon = "di:glance";
    status = {
      title = "Gatus";
      icon = "di:gatus";
    };
  };

  nameOf = host: lib.head (lib.splitString "." host);
  groupOf = name: if lib.elem name media then "media" else "homelab";

  site =
    host:
    let
      name = nameOf host;
    in
    {
      title = lib.toSentenceCase name;
      url = "https://${host}";
      icon = "di:${name}";
    }
    // overrides.${name} or { };

  hosts = lib.filter (host: host != "_" && groupOf (nameOf host) == group) (
    lib.attrNames nodes.ingress.config.services.nginx.virtualHosts
  );
in
{
  type = "monitor";
  title = "Services";
  cache = "1m";
  sites = lib.sortOn (site: lib.toLower site.title) (map site hosts);
}
