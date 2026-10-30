{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # file manager + disk/image utilities; rides any desktop session
  config = lib.mkIf osConfig.cfg.desktop.enable {
    home.packages = with pkgs; [
      nemo-with-extensions
      gparted
      pinta
    ];
  };
}
