{
  lib,
  ...
}:
{
  # Home-manager feature options, declared in the NixOS tree so hosts set every
  # knob under the single cfg.* namespace; home modules are option-less and read
  # these via osConfig.cfg.home.*. Most default true (hosts opt OUT) and gate on
  # cfg.desktop.enable home-side, so headless hosts stay clean.
  options.cfg.home = {
    shell.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "zsh + catlinux theme + modern CLI tools";
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

    # desktop app bundles — droppable per host; the installer ISO turns all off
    vscode.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "VS Code with the profile's settings and extensions";
    };

    desktopApps.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "nemo-with-extensions, gparted, pinta";
    };

    brave.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Brave browser";
    };

    mpv.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "mpv media player";
    };

    pinta.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pinta image editor (split from the desktopApps bundle — pulls dotnet)";
    };

    ytDlp.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "yt-dlp in the CLI bundle (pulls the deno runtime — heavy)";
    };

    prefetchTools.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "nix-prefetch-git/-github CLIs (their nix-*-dev closure is heavy)";
    };

    theming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Runtime wallpaper theming (matugen): one palette extracted from the
          running wallpaper feeds the quickshell bar, kitty, mako, gtk, rofi
          and hyprlock. waypaper is the wallpaper picker; needs a wallpaper
          to be set.
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

    hyprland.lock = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        hypridle + hyprlock screen-lock stack (idle auto-lock, SUPER+L,
        sleep lock). One toggle for the pair — hypridle's lock_cmd invokes
        hyprlock, so they only make sense together. Off also drops
        brightnessctl (the dim listeners' only consumer). Passwordless
        accounts (the installer's live `nixos` user) must turn this off:
        nothing typed unlocks hyprlock against an empty shadow hash.
      '';
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
