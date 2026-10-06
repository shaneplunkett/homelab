_:
let
  shane = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfq31bP+xQwlO/joZeGU6LaLYZXV2ql7TLSv5ToVUtJ";
  dashboard = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOslO4NV6X1Rk1AkNPkIg7AndhYeMAI3lz/jKJOQ3IPo";

in
{
  "proxmox-token.age".publicKeys = [
    shane
    dashboard
  ];
}
