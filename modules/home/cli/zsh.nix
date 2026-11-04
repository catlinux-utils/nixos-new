{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.cfg.home.shell.enable {
    # command-not-found via nix-index (per-package database, zsh hook)
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

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
        # lsd's zsh integration defines its own ls/ll/la — keep the custom ones
        ls = lib.mkForce "lsd";
        ll = lib.mkForce "lsd -l";
        la = lib.mkForce "lsd -la";
        l = "ll";
      };

      # the catlinux prompt theme (ported from the legacy flake) — replaces
      # starship, which was removed with the port (the theme owns the prompt)
      plugins = [
        {
          name = "catlinux-zsh-theme";
          file = "catlinux.zsh-theme";
          src = pkgs.fetchFromGitHub {
            owner = "catlinux-utils";
            repo = "catlinux-zsh-theme";
            rev = "9b322e025e75e8704523b1ee84cf2e3ca90824c0";
            sha256 = "sha256-8bTuKIldIQZhpLtex2RsDiJt76nduml/B6tsxNPSoeU=";
          };
        }
      ];

      # ollama subcommand + model completions (ported from the legacy flake)
      initContent = ''
        # nix-index's command-not-found handler spams a database error when the
        # index hasn't been built yet (live media, fresh hosts) — plain message
        # instead until `nix-index` has been run once. initContent runs after
        # the integrations, so this wins on shells without the DB.
        if ! [ -e "$HOME/.cache/nix-index/files" ]; then
          command_not_found_handler() {
            echo "zsh: command not found: $1" >&2
            return 127
          }
        fi

        _ollama() {
          local curcontext="$curcontext" state line
          typeset -A opt_args
          local -a commands

          commands=(
            'serve:Start ollama'
            'create:Create a model from a Modelfile'
            'show:Show information for a model'
            'run:Run a model'
            'stop:Stop a running model'
            'pull:Pull a model from a registry'
            'push:Push a model to a registry'
            'list:List models'
            'ps:List running models'
            'cp:Copy a model'
            'rm:Remove a model'
            'help:Help any command'
          )

          _arguments -C \
            '1: :->command' \
            '*:: :->args'

          case $state in
            (command)
              _describe -t commands 'ollama commands' commands
              ;;
            (args)
              case $line[1] in
                (run|pull|show|rm|cp|stop)
                  local -a models
                  models=(''${(f)"$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')"})
                  compadd -a models
                  ;;
                (create)
                  _arguments '-f[Specify Modelfile]:filename:_files'
                  ;;
                (push)
                  _arguments '1:model name' '2:destination'
                  ;;
                (list|ps|serve)
                  ;;
                (help)
                  _describe -t commands 'ollama commands' commands
                  ;;
              esac
              ;;
          esac
        }

        compdef _ollama ollama
      '';
    };

    programs.fzf.enable = true;
    programs.lsd = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.btop = {
      enable = true;
      # AMD GPU monitoring (legacy-flake port)
      package = pkgs.btop.override { rocmSupport = true; };
      settings = {
        color_theme = "TTY";
        theme_background = false;
        update_ms = 2000;
        rounded_corners = true;
      };
    };
    programs.bat.enable = true;
    programs.zoxide.enable = true;
    programs.atuin = {
      enable = true;
      # atuin's default up-arrow binding opens its full-screen history TUI —
      # keep plain zsh history on ↑, atuin search stays on ctrl-r
      flags = [ "--disable-up-arrow" ];
    };
    programs.yazi.enable = true;
    programs.lazygit.enable = true;
    programs.tealdeer.enable = true;

    # general-purpose utilities (no programs.* wrapper exists for these)
    home.packages = with pkgs; [
      fastfetch
      onefetch
      tokei
      yt-dlp
      ffmpeg
      ncdu
      duf
      unzip
      p7zip
      nix-tree
      nix-prefetch-git
      nix-prefetch-github
    ];
  };
}
