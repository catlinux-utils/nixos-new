{
  lib,
  osConfig,
  inputs,
  ...
}:
{
  # plasma-manager rides every host — the import is inert without the
  # switch (its config gates on programs.plasma.enable); no host enables
  # cfg.desktop.plasma.enable yet, this is wired ahead of that
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  config = lib.mkIf osConfig.cfg.desktop.plasma.enable {
    programs.plasma = {
      enable = true;

      # minimal sane defaults, mirroring gnome.nix; extend as preferences
      # emerge. overrideConfig stays unset (false) — KDE settings made
      # outside plasma-manager are preserved
      workspace.lookAndFeel = "org.kde.breezedark.desktop";
    };
  };
}
