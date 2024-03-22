{lib}: {
  enableStupidFeatures ? false,
  enableIDEFeatures ? false,
  enableDesktop ? enableIDEFeatures,
}: let
  inherit (lib) mkIf mkMerge optionals;

  l = "<leader>";
in {
  colorschemes.catppuccin.enable = true;
  vimAlias = true;
  viAlias = true;

  globals.mapleader = " ";
  options = {
    relativenumber = true;
    number = true;
    mouse =
      if enableIDEFeatures
      then "a"
      else "";
  };
  keymaps = optionals enableIDEFeatures [
    {
      key = "${l}bn";
      action = "<cmd>bnext<CR>";
      options = {
        desc = "Goto next buffer";
        silent = true;
      };
    }
    {
      key = "${l}bp";
      action = "<cmd>bprevious<CR>";
      options = {
        desc = "Goto previous buffer";
        silent = true;
      };
    }
    {
      key = "${l}bc";
      action = "<cmd>bdelete<CR>";
      options = {
        desc = "Close current buffer";
        silent = true;
      };
    }
    {
      key = "${l}bl";
      action = "<cmd>buffers<CR>";
      options.desc = "List all buffers";
    }
  ];

  clipboard.providers.xclip.enable = enableDesktop;
  clipboard.register = ["unnamed"];
  plugins = mkMerge [
    {
      nvim-colorizer.enable = true;
      todo-comments.enable = true;
      rainbow-delimiters.enable = true;
      which-key = {
        enable = true;
        registrations = {
          "${l}l" = "+lsp";
        };
      };
    }
    (mkIf enableIDEFeatures {
      nvim-tree = {
        enable = true;
        hijackCursor = true;
      };
      bufferline.enable = true;
      lsp = {
        enable = true;
        servers = {
          html.enable = true;
          bashls.enable = true;
          rust-analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
          nil_ls.enable = true;
          cmake.enable = true;
          clangd.enable = true;
          pylsp.enable = true;
        };
        keymaps = {
          lspBuf = {
            "${l}lf" = {
              action = "format";
              desc = "Format";
            };
            "${l}ln" = {
              action = "rename";
              desc = "Rename symbol";
            };
            "${l}lc" = {
              action = "code_action";
              desc = "Code action";
            };
            "${l}lh" = {
              action = "signature_help";
              desc = "Help";
            };
          };
        };
      };
      nvim-lightbulb.enable=true;
      lsp-lines.enable = true;
      fidget.enable = true;
      lualine = {
        enable = true;
        theme = "catppuccin";
      };
      cmp-nvim-lsp.enable = true;
      cmp.enable = true;
      gitsigns = {
        enable = true;
      };
      treesitter.enable = true;
      trouble.enable = true;
      typst-vim.enable = true;
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
