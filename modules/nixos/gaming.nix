{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.gaming.enable = lib.mkEnableOption "gaming (Steam, gamescope, GameMode, MangoHud)";

  config = lib.mkIf config.cfg.gaming.enable {
    cfg.graphics.enable = lib.mkDefault true;
    cfg.graphics.enable32Bit = lib.mkDefault true;

    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
    };

    hardware.steam-hardware.enable = true;
    programs.gamemode.enable = true;

    # NixOS dropped the programs.mangohud module in 26.05; the package plus
    # `mangohud %command%` is all Steam needs (HM-side config can come later)
    environment.systemPackages = [ pkgs.mangohud ];

    # Xbox Bluetooth controllers
    hardware.xpadneo.enable = true;
  };
}
