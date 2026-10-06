let
  shane = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfq31bP+xQwlO/joZeGU6LaLYZXV2ql7TLSv5ToVUtJ";
  dashboard = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOslO4NV6X1Rk1AkNPkIg7AndhYeMAI3lz/jKJOQ3IPo";
  monitoring = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA22/YPhM1xo8VJPcessZzNQ1PzFtpKZ7lGltOmffZjx";
  ingress = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAe172XoKAZeWtcPmuuFibRFG1Jdlpv/atTRfHtVfezB";
  dns1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFUXb6HM8jMHJvC7/Uy1f0MMjSMmm78W0xH58X7vBENY";
  dns2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbYHIaGpPpaZxcJT6zHry6kCbXjX50+jQZMuHKgkvFQ";
  plex = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOEtYm68pdXcUDG9IUOLJ+9Nv/F8qRF9ne2jnVrBH/v6";

in
{
  "proxmox-token.age".publicKeys = [
    shane
    dashboard
  ];
  "discord-webhook.age".publicKeys = [
    shane
    dashboard
    monitoring

  ];
  "pve-exporter.age".publicKeys = [
    shane
    monitoring

  ];
  "grafana-admin-password.age".publicKeys = [
    shane
    monitoring

  ];
  "grafana-secret-key.age".publicKeys = [
    shane
    monitoring

  ];
  "cloudflare-dns.age".publicKeys = [
    shane
    ingress

  ];
  "linear-api-key.age".publicKeys = [
    shane
    dashboard
  ];
  "backup-dashboard.age".publicKeys = [
    shane
    dashboard
  ];
  "backup-plex.age".publicKeys = [
    shane
    plex
  ];
  "hetzner-api-token.age".publicKeys = [
    shane
    monitoring
  ];
  "tailscale-oauth.age".publicKeys = [
    shane
    dashboard
    monitoring
    ingress
    dns1
    dns2
    plex
  ];
}
