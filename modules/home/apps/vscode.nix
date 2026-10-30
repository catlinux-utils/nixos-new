{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # rides the system desktop switch — the headless vscode-server story is
  # nix-ld (modules/nixos/compat.nix), not a local editor install
  config = lib.mkIf osConfig.cfg.desktop.enable {
    programs.vscode = {
      enable = true;

      # argv.json — UI locale and the secrets backend (gnome-keyring is set up
      # system-side in modules/nixos/desktop/hyprland.nix)
      argvSettings = {
        "locale" = "pl";
        "enable-crash-reporter" = false;
        "password-store" = "gnome-libsecret";
      };

      profiles.default = {
        userSettings = {
          "update.mode" = "none";
          "update.showReleaseNotes" = false;
          "window.customTitleBarVisibility" = "auto";
          "window.titleBarStyle" = "custom";
          "workbench.activityBar.location" = "top";
          "workbench.sideBar.location" = "right";
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
          "telemetry.telemetryLevel" = "off";
          "explorer.confirmDragAndDrop" = false;
          "editor.formatOnSave" = true;
          "editor.formatOnPaste" = true;
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };
          "git.confirmSync" = false;
          "git.suggestSmartCommit" = false;
          "diffEditor.maxComputationTime" = 0;
          "diffEditor.hideUnchangedRegions.enabled" = true;
          "editor.unicodeHighlight.ambiguousCharacters" = false;
          "chat.viewSessions.orientation" = "stacked";
        };

        extensions = with pkgs.vscode-extensions; [
          esbenp.prettier-vscode
          eamodio.gitlens
          donjayamanne.githistory
          mhutchie.git-graph
          github.vscode-pull-request-github
          jnoortheen.nix-ide
          ms-ceintl.vscode-language-pack-pl
          github.copilot
          github.copilot-chat
        ];
      };
    };
  };
}
