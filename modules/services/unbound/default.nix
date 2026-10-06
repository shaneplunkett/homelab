_: {
  services.unbound = {
    enable = true;
    settings.server = {
      port = 5335;
      serve-expired = true;
    };
  };
}
