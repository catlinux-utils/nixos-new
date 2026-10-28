{
  lib,
  osConfig,
  ...
}:
{
  # rides the system desktop switch — no browser on headless hosts
  config = lib.mkIf osConfig.cfg.desktop.enable {
    # native HM namespace (not the legacy programs.chromium wrapper trick):
    # release-26.05 supports brave directly, incl. its BraveSoftware config dir
    programs.brave = {
      enable = true;
      commandLineArgs = [
        "--password-store=gnome-libsecret" # gnome-keyring, wired in desktop/hyprland.nix
        "--enable-accelerated-video-decode"
        "--disable-features=WaylandWpColorManagerV1"
      ];
    };

    # one writer per key: xdg.nix owns the text/* mime keys, this owns the web ones
    xdg.mimeApps.defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
    };
  };
}
