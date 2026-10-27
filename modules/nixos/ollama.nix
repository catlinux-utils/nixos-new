{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.cfg.ollama = {
    enable = lib.mkEnableOption "the Ollama local-LLM server";

    rocmGfx = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        GFX version override for AMD GPUs (feeds
        services.ollama.rocmOverrideGfx), e.g. "10.3.0". null keeps the stock
        ollama package and no override.
      '';
    };
  };

  config = lib.mkIf config.cfg.ollama.enable (lib.mkMerge [
    { services.ollama.enable = true; }

    (lib.mkIf (config.cfg.ollama.rocmGfx != null) {
      services.ollama = {
        package = pkgs.ollama-rocm;
        rocmOverrideGfx = config.cfg.ollama.rocmGfx;
        environmentVariables = {
          HIP_VISIBLE_DEVICES = "0";
          OLLAMA_FLASH_ATTENTION = "0";
        };
      };
    })
  ]);
}
