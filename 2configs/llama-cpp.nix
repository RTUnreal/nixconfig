{ config, nixpkgs-unstable, ... }: {
  services.llama-cpp = {
    enable = true;
    package = nixpkgs-unstable.llama-cpp-vulkan;
    host = "0.0.0.0";
    modelsPreset = {
      "Qwen3.6-35B-A3B" = {
        hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
        ctx-size = 0;
      };
      "Qwen3.8-27B" = {
        hf-repo = "unsloth/Qwen3.8-27B-GGUF:UD-IQ3_S";
        ctx-size = 0;
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ config.services.llama-cpp.port ];
}
