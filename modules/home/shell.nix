{
  lib,
  osConfig,
  config,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.shell.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 10000;
        save = 10000;
        path = "${config.xdg.dataHome}/zsh/history";
        ignoreDups = true;
        share = true;
      };
      shellAliases = {
        ls = "eza --icons";
        ll = "eza --icons -l";
        la = "eza --icons -la";
      };
    };

    programs.starship.enable = true;
    programs.fzf.enable = true;
    programs.eza.enable = true;
    programs.btop.enable = true;
    programs.bat.enable = true;
    programs.zoxide.enable = true;
    programs.atuin.enable = true;
    programs.yazi.enable = true;
    programs.lazygit.enable = true;
    programs.tealdeer.enable = true;
  };
}
