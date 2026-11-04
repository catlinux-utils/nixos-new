{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # file manager + disk/image utilities; rides any desktop session;
  # cfg.home.desktopApps.enable drops it per host. Pinta is split out
  # (cfg.home.pinta.enable) — it pulls the whole dotnet runtime.
  config = lib.mkMerge [
    (lib.mkIf (osConfig.cfg.desktop.enable && osConfig.cfg.home.desktopApps.enable) {
      home.packages = with pkgs; [
        nemo-with-extensions
        gparted
      ];
    })

    (lib.mkIf (osConfig.cfg.desktop.enable && osConfig.cfg.home.pinta.enable) {
      home.packages = [ pkgs.pinta ];
    })
  ];
}
