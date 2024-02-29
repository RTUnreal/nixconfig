{lib}: {
  enableIDEFeatures,
  enableDesktop,
}: let
  inherit (lib) mkIf;
in {
  colorschemes.gruvbox.enable = true;
  clipboard.providers.xclip.enable = enableDesktop;
  clipboard.register = ["unnamed"];
  lsp = mkIf enableIDEFeatures {
    enable = true;
  };
}
