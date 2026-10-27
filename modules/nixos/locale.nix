{
  lib,
  config,
  ...
}:
{
  options.cfg.locale = {
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Warsaw";
      description = "IANA timezone for the host.";
    };
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Default system locale.";
    };
    keyboard = lib.mkOption {
      type = lib.types.str;
      default = "pl";
      description = ''
        Keyboard layout — sets both the console keymap and the X/Wayland
        layout (GDM reads the latter).
      '';
    };
  };

  config = {
    time.timeZone = config.cfg.locale.timeZone;
    i18n.defaultLocale = config.cfg.locale.defaultLocale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.cfg.locale.defaultLocale;
      LC_IDENTIFICATION = config.cfg.locale.defaultLocale;
      LC_MEASUREMENT = config.cfg.locale.defaultLocale;
      LC_MONETARY = config.cfg.locale.defaultLocale;
      LC_NAME = config.cfg.locale.defaultLocale;
      LC_NUMERIC = config.cfg.locale.defaultLocale;
      LC_PAPER = config.cfg.locale.defaultLocale;
      LC_TELEPHONE = config.cfg.locale.defaultLocale;
      LC_TIME = config.cfg.locale.defaultLocale;
    };
    console.keyMap = config.cfg.locale.keyboard;
    services.xserver.xkb.layout = config.cfg.locale.keyboard;
  };
}
