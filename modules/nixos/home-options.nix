{
  lib,
  ...
}:
{
  # Options for home-manager features, declared in the NixOS tree so hosts
  # set every knob under the single cfg.* namespace. The home modules are
  # option-less and read these via osConfig.cfg.home.*.
  options.cfg.home = {
    shell.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "zsh + starship + modern CLI tools";
    };

    git = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "git + delta + lfs";
      };
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "git user.name (null = not set).";
      };
      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "git user.email (null = not set).";
      };
    };

    terminal.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "kitty terminal";
    };

    neovim.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Neovim as the default editor";
    };

    xdg.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "XDG base dirs, user dirs and mime defaults";
    };

    tools.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "home-manager CLI in the user environment";
    };

    direnv.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "direnv + nix-direnv (per-project dev shells)";
    };

    nix-index.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "nix-index database + comma (command-not-found, `,pkg` runner)";
    };

    gpg.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "gpg + gpg-agent with ssh-agent support";
    };

    ssh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "ssh client defaults (agent, connection multiplexing)";
    };

    easyeffects.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "EasyEffects daemon (PipeWire EQ/compressor); needs audio + a desktop session";
    };

    password-store.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "pass (password store; pairs with gpg)";
    };

    tmux.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "tmux — opt-in; hosts that serve ssh sessions flip this on";
    };

    obs.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "OBS Studio — opt-in screen recording";
    };

    theming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Runtime wallpaper theming (matugen): one palette extracted from the
          running wallpaper feeds the quickshell bar, kitty, mako and gtk.
          waypaper is the wallpaper picker; needs a wallpaper to be set.
        '';
      };
      wallpapers = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = ''
          Wallpaper collection installed to ~/Pictures/Wallpapers for the
          waypaper picker. Only used when theming.enable is set.
        '';
      };
    };

    hyprland.wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Install-time default wallpaper — seeds ~/.local/state/theming/current
        exactly once (the state copy is authoritative afterwards). Also gates
        hyprpaper; null disables it. Requires theming.enable for the seed.
      '';
    };
  };
}
