{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.shell.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      # case-insensitive tab completion
      completionInit = ''
        autoload -U compinit && compinit
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      '';
      history = {
        size = 10000;
        save = 10000;
        path = "${config.xdg.dataHome}/zsh/history";
        ignoreDups = true;
        share = true;
      };
      shellAliases = {
        cat = "bat";
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

    # general-purpose utilities (no programs.* wrapper exists for these)
    home.packages = with pkgs; [
      yt-dlp
      ffmpeg
      ncdu
      duf
      unzip
      p7zip
    ];
  };
}
