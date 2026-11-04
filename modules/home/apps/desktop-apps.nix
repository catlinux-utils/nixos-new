{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # file manager + disk/image utilities; rides any desktop session;
  # cfg.home.desktopApps.enable drops it per host (the installer ISO does)
  config = lib.mkIf (osConfig.cfg.desktop.enable && osConfig.cfg.home.desktopApps.enable) {
    home.packages = with pkgs; [
      nemo-with-extensions
      gparted
      pinta
    ];
  };
}
