{
  lib,
  osConfig,
  inputs,
  ...
}:
{
  # plasma-manager rides every host — the import is inert without the switch
  # (config gates on programs.plasma.enable); wired ahead of any host using it
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  config = lib.mkIf osConfig.cfg.desktop.plasma.enable {
    programs.plasma = {
      enable = true;

      # overrideConfig stays unset (false) — KDE settings made outside
      # plasma-manager are preserved
      workspace.lookAndFeel = "org.kde.breezedark.desktop";
    };
  };
}
