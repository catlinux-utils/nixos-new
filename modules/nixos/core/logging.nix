{
  lib,
  ...
}:
{
  # Always on: an unbounded journal is a silent disk-filler, so every host
  # persists the journal across reboots with a hard size cap.
  services.journald = {
    storage = "persistent";
    extraConfig = ''
      SystemMaxUse=1G
    '';
  };
}
