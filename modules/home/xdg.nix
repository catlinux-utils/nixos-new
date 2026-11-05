{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.xdg.enable {
    xdg = {
      enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "$HOME/Desktop";
        documents = "$HOME/Documents";
        download = "$HOME/Downloads";
        music = "$HOME/Music";
        pictures = "$HOME/Pictures";
        publicShare = "$HOME/Public";
        templates = "$HOME/Templates";
        videos = "$HOME/Videos";
      };

      mimeApps = {
        enable = true;
        # nvim.desktop comes from cli/neovim.nix (independently flippable) —
        # gate so defaults don't dangle without it
        defaultApplications = lib.mkIf osConfig.cfg.home.neovim.enable {
          "text/plain" = [ "nvim.desktop" ];
          "text/markdown" = [ "nvim.desktop" ];
          "application/json" = [ "nvim.desktop" ];
        };
      };
    };
  };
}
