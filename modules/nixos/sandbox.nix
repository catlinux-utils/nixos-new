{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.sandbox = {
    flatpak.enable = lib.mkEnableOption "Flatpak with the Flathub remote and Flatseal";
    firejail.enable = lib.mkEnableOption "Firejail sandboxing";
  };

  config = lib.mkMerge [
    (lib.mkIf config.cfg.sandbox.flatpak.enable {
      services.flatpak.enable = true;

      # Flathub bootstrap (26.05's services.flatpak has no remotes option;
      # Flatseal has no nixpkgs attr on 26.05). Needs network-online: without
      # it the unit fails on boots where the net isn't up yet
      systemd.services.flatpak-flathub = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.flatpak ];
        script = ''
          flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.repo
          flatpak install --noninteractive --or-update flathub com.github.tchx84.Flatseal
        '';
      };
    })

    (lib.mkIf config.cfg.sandbox.firejail.enable {
      programs.firejail.enable = true;
    })
  ];
}
