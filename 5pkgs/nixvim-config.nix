{lib}: {
  enableStupidFeatures ? false,
  enableIDEFeatures ? false,
  enableDesktop ? enableIDEFeatures,
}: let
  inherit (lib) mkIf mkMerge;
in {
  colorschemes.catppuccin.enable = true;
  vimAlias = true;
  viAlias = true;
  options = {
    relativenumber = true;
    number = true;
    mouse =
      if enableIDEFeatures
      then "a"
      else "";
  };
  clipboard.providers.xclip.enable = enableDesktop;
  clipboard.register = ["unnamed"];
  plugins = mkMerge [
    {
      nvim-colorizer.enable = true;
      todo-comments.enable = true;
    }
    (mkIf enableIDEFeatures {
      nvim-tree = {
        enable = true;
        hijackCursor = true;
      };
      lsp = {
        enable = true;
        servers = {
          rust-analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
          nixd.enable = true;
        };
      };
      fidget.enable = true;
      lualine = {
        enable = true;
        theme = "catppuccin";
      };
      cmp-nvim-lsp.enable = true;
      nvim-cmp.enable = true;
      gitsigns = {
        enable = true;
      };
      noice.enable = true;
    })
    (mkIf enableStupidFeatures {
      neocord = {
        enable = true;
        settings = {
          client_id = "793271441293967371";
          auto_update = true;
          logo_tooltip = "The Superior Text Editor";
          main_image = "logo";
          show_time = true;
        };
      };
    })
  ];
}
