# Keyboard/button remapping daemon (system service) + GTK GUI (same package).
# Upstream keeps enableUdevRules off by default (known hotplug issue) —
# plugged-in devices still work.
{
  lib,
  config,
  ...
}:
{
  options.cfg.inputRemapper.enable = lib.mkEnableOption "input-remapper, input-device button remapping";

  config = lib.mkIf config.cfg.inputRemapper.enable {
    services.input-remapper.enable = true;
  };
}
