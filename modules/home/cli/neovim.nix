{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.neovim.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # desktop entry so xdg mime defaults can point at nvim
    xdg.desktopEntries.nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      exec = "nvim %F";
      terminal = true;
      categories = [
        "Utility"
        "TextEditor"
      ];
    };
  };
}
