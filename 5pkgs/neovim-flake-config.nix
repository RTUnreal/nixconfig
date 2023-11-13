{
  config = {
    vim = {
      viAlias = true;
      vimAlias = true;
      debugMode = {
        enable = false;
        level = 20;
        logFile = "/tmp/nvim.log";
      };
    };

    vim.lsp = {
      formatOnSave = true;
      lspkind.enable = false;
      lightbulb.enable = true;
      lspsaga.enable = false;
      nvimCodeActionMenu.enable = true;
      trouble.enable = true;
      lspSignature.enable = true;
      lsplines.enable = true;
      nvim-docs-view.enable = true;
    };

    vim.debugger = {
      nvim-dap = {
        enable = true;
        ui.enable = true;
      };
    };

    vim.languages = {
      enableLSP = true;
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      html.enable = true;
      clang = {
        enable = true;
        lsp.server = "clangd";
      };
      sql.enable = true;
      rust = {
        enable = true;
        crates.enable = true;
      };
      ts.enable = true;
      ts.lsp.enable = true;
      go.enable = true;
      #zig.enable = isMaximal;
      python.enable = true;
      #dart.enable = isMaximal;
      elixir.enable = false;
      bash.enable = true;
    };

    vim.visuals = {
      enable = true;
      nvimWebDevicons.enable = true;
      scrollBar.enable = true;
      smoothScroll.enable = true;
      cellularAutomaton.enable = false;
      fidget-nvim.enable = true;
      highlight-undo.enable = true;

      indentBlankline = {
        enable = true;
        fillChar = null;
        eolChar = null;
        showCurrContext = true;
      };

      cursorline = {
        enable = true;
        lineTimeout = 0;
      };
    };

    vim.statusline = {
      lualine = {
        enable = true;
        theme = "catppuccin";
      };
    };

    vim.theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
      transparent = false;
    };
    vim.autopairs.enable = true;

    vim.autocomplete = {
      enable = true;
      type = "nvim-cmp";
    };

    vim.filetree = {
      nvimTree = {
        enable = true;
      };
    };

    vim.tabline = {
      nvimBufferline.enable = true;
    };

    vim.treesitter.context.enable = true;

    vim.binds = {
      whichKey.enable = true;
      cheatsheet.enable = true;
    };

    vim.telescope.enable = true;

    vim.git = {
      enable = true;
      gitsigns.enable = true;
      gitsigns.codeActions = false; # throws an annoying debug message
    };

    vim.minimap = {
      minimap-vim.enable = false;
      codewindow.enable = true; # lighter, faster, and uses lua for configuration
    };

    vim.dashboard = {
      dashboard-nvim.enable = false;
    };

    vim.notify = {
      nvim-notify.enable = true;
    };

    vim.utility = {
      ccc.enable = true;
      #icon-picker.enable = isMaximal;
      surround.enable = true;
      diffview-nvim.enable = true;
      motion = {
        hop.enable = true;
        leap.enable = true;
      };
    };

    vim.notes = {
      todo-comments.enable = true;
    };

    vim.terminal = {
      toggleterm = {
        enable = true;
        lazygit.enable = true;
      };
    };

    vim.ui = {
      borders.enable = true;
      noice.enable = true;
      colorizer.enable = true;
      modes-nvim.enable = false; # the theme looks terrible with catppuccin
      illuminate.enable = true;
      breadcrumbs = {
        enable = true;
        navbuddy.enable = true;
      };
      smartcolumn = {
        enable = true;
        columnAt.languages = {
          # this is a freeform module, it's `buftype = int;` for configuring column position
          nix = 110;
          ruby = 120;
          java = 130;
          go = [90 130];
        };
      };
    };

    vim.session = {
      nvim-session-manager.enable = false;
    };

    vim.gestures = {
      gesture-nvim.enable = false;
    };

    vim.comments = {
      comment-nvim.enable = true;
    };

    vim.presence = {
      presence-nvim = {
        enable = true;
        auto_update = true;
        image_text = "The Superior Text Editor";
        client_id = "793271441293967371";
        main_image = "neovim";
        show_time = true;
        rich_presence = {
          editing_text = "Editing %s";
        };
      };
    };
  };
}
