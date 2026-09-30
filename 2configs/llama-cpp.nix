{
  config,
  nixpkgs-unstable,
  pkgs,
  ...
}:
let
  llama-monitor = pkgs.writeShellApplication {
    name = "llama-monitor";
    runtimeInputs = with pkgs; [
      tmux
      htop
      pkgs.nvtopPackages.amd
    ];
    text = ''
      SESSION="llama-monitor-$$"
      if tmux has-session -t $SESSION 2>/dev/null; then
        tmux kill-session -t $SESSION
      fi
      tmux new-session -d -s $SESSION nvtop \; \
        split-window -v -t $SESSION journalctl -xefu llama-cpp \; \
        split-window -h -t $SESSION.0 htop \; \
        select-pane -t $SESSION.0 \; \
        attach -t $SESSION
    '';
  };
in
{
  services.llama-cpp = {
    enable = true;
    package = nixpkgs-unstable.llama-cpp-rocm;
    host = "0.0.0.0";
    modelsPreset = {
      "Qwen3.6-35B-A3B" = {
        hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";

        # 16 GB VRAM: keep attention + KV on GPU, push some MoE experts to CPU.
        # Lower this number until you run out of VRAM, then back off by 1-2.
        n-cpu-moe = "22";

        ctx-size = "131072";
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";

        batch-size = "2048";
        ubatch-size = "1024";
        threads = "8";
        threads-batch = "8";
        parallel = "1";

        spec-type = "draft-mtp";
        spec-draft-n-max = "3";

        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };
      "Qwen3.8-27B" = {
        hf-repo = "unsloth/Qwen3.8-27B-GGUF:UD-Q3_K_XL";
        ctx-size = "32768";
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";
        batch-size = "2048";
        ubatch-size = "1024";
        threads = "8";
        parallel = "1";

        spec-type = "draft-mtp";
        spec-draft-n-max = "3";

        temp = "0.6";
        top-p = "0.95";
        top-k = "20";

        n-gpu-layers = "62";
        flash-attn = "on";
        jinja = "true";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ config.services.llama-cpp.port ];

  environment.systemPackages = [
    llama-monitor
  ];
}
