_: {

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    allowedHosts = "192.168.1.152:8082";
    services = [
      {
        "Infrastructure" = [
          {
            "Proxmox" = {
              href = "https://proxmox.shaneplunkett.com";
              description = "Proxmox";
              icon = "proxmox.png";
            };
          }
        ];

      }
    ];
  };
}
