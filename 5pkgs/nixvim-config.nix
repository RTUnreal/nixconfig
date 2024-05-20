{
  pkgs,
  lib,
}: {
  enableSillyFeatures ? false,
  enableIDEFeatures ? false,
  enableDesktop ? enableIDEFeatures,
}: let
  inherit (lib) mkIf mkMerge optionals;

  l = "<leader>";
in {
  colorschemes.catppuccin.enable = true;
  vimAlias = true;
  viAlias = true;

  globals = {
    mapleader = " ";
    formatOnSave = true;
  };
  opts = {
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
    {
      key = "${l}tn";
      action = ''
        function()
          vim.o.signcolumn = vim.o.signcolumn ~= "no" and "no" or "auto"
          vim.o.mouse = vim.o.mouse ~= "a" and "a" or ""
          vim.o.number = not vim.o.number
          vim.o.relativenumber = not vim.o.relativenumber
        end
      '';
      lua = true;
      options.desc = "Toggle terminal copy mode";
    }
    {
      key = "${l}tr";
      action = "<cmd>NvimTreeToggle<CR>";
      options.desc = "Toggle NvimTree";
    }
    {
      key = "${l}tf";
      # from lsp-format
      action = "<cmd>FormatToggle<CR>";
      options.desc = "Toggle formating on save";
    }
  ];

  clipboard.providers.xclip.enable = enableDesktop;
  clipboard.register = ["unnamed"];
  plugins = mkMerge [
    {
      nvim-colorizer.enable = true;
      todo-comments.enable = true;
      which-key = {
        enable = true;
        registrations = {
          "${l}l" = "+lsp";
          "${l}t" = "+toggle";
        };
      };
    }
    (mkIf enableIDEFeatures {
      nvim-tree = {
        enable = true;
        hijackCursor = true;
      };
      bufferline = {
        enable = true;
        offsets = [
          {
            filetype = "NvimTree";
            text = "File Explorer";
            highlight = "Directory";
            separator = true;
          }
        ];
      };
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
          nil_ls = {
            enable = true;
            settings.formatting.command = ["${lib.getExe pkgs.alejandra}" "--quiet"];
          };
          cmake.enable = true;
          clangd.enable = true;
          pylsp.enable = true;
          elixirls.enable = true;
          phpactor = {
            enable = true;
            cmd = ["phpactor" "language-server" "--config-extra" "{\"language_server_php_cs_fixer.enabled\":true}"];
          };
        };
        keymaps = {
          lspBuf = {
            "${l}lf" = {
              action = "format";
              desc = "Format";
            };
            "${l}lr" = {
              action = "references";
              desc = "Show references";
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
            "${l}lgd" = {
              action = "definition";
              desc = "Definition";
            };
            "${l}lgD" = {
              action = "declaration";
              desc = "Declaration";
            };
          };
        };
      };
      nvim-lightbulb.enable = true;
      lsp-lines.enable = true;
      lsp-format.enable = true;
      fidget.enable = true;
      lualine = {
        enable = true;
        theme = "catppuccin";
      };
      luasnip.enable = true;
      cmp = {
        enable = true;

        settings = {
          window = {
            completion.__raw = "cmp.config.window.bordered()";
            documentation.__raw = "cmp.config.window.bordered()";
          };
          sources = [{name = "nvim_lsp";} {name = "luasnip";}];
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          mapping = {
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          };
        };
      };
      crates-nvim.enable = true;
      gitsigns.enable = true;
      treesitter.enable = true;
      rainbow-delimiters.enable = true;
      trouble.enable = true;
      typst-vim.enable = true;
      noice.enable = true;
    })
    (mkIf enableSillyFeatures {
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
