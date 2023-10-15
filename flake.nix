{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    retiolum.url = "git+https://git.thalheim.io/Mic92/retiolum";
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    neovim-flake = {
      url = "github:notashelf/neovim-flake/fc8206e7a61d7eb02006f9010e62ebdb3336d0d2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = {
    self,
    nix-gaming,
    nixpkgs,
    nixinate,
    nixpkgs-unstable,
    neovim-flake,
    retiolum,
    treefmt-nix,
    systems,
    ...
  }: let
    # Small tool to iterate over each systems
    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (system:
        f (import nixpkgs {
          inherit system;
        }));

    treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
  in {
    nixosModules = {
      base = import ./2configs/base.nix;
      base-pc = import ./2configs/base-pc.nix;
      base-server = import ./2configs/base-server.nix;
      bluetooth = import ./2configs/bluetooth.nix;
      docker = import ./2configs/docker.nix;
      mpv = import ./2configs/mpv.nix;
      nvidia-prime = import ./2configs/nvidia-prime.nix;
      steam = import ./2configs/steam.nix;
      virtualization = import ./3modules/virtualisation.nix;
      wacom = import ./2configs/wacom.nix;

      devel-forge = import ./2configs/devel/forge.nix;
      devel-ci = import ./2configs/devel/ci.nix;
    };

    nixosConfigurations = let
      pinned-nixpkgs = {
        nix.registry.nixpkgs.flake = nixpkgs;
      };
      unfreePkgs = {
        system,
        allowedUnfree,
      }:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs-unstable.legacyPackages."${system}".lib.getName pkg) allowedUnfree;
        };
    in
      {
        runner =
          nixpkgs.lib.nixosSystem
          rec {
            system = "x86_64-linux";
            specialArgs = {
              nixpkgs-unstable = unfreePkgs {
                inherit system;
                allowedUnfree = [
                  "steam"
                  "steam-original"
                  "steam-run"

                  "zoom"
                  "anydesk"

                  "vscode-extension-ms-vscode-cpptools"
                ];
              };
              selfpkgs = self.packages.${system};
            };
            modules = [
              pinned-nixpkgs
              retiolum.nixosModules.retiolum
              ./1systems/runner/config.nix
            ];
          };
        spinner = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            nixpkgs-unstable = unfreePkgs {
              inherit system;
              allowedUnfree = [
                "steam"
                "steam-original"
                "steam-run"

                "zoom"
                "anydesk"

                "nvidia-x11"
                "nvidia-settings"

                "vscode-extension-ms-vscode-cpptools"
              ];
            };
            selfpkgs = self.packages.${system};
          };
          modules = [
            pinned-nixpkgs
            retiolum.nixosModules.retiolum
            self.nixosModules.virtualization
            ./1systems/spinner/config.nix
          ];
        };
        devel = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            nixpkgs-unstable = nixpkgs-unstable.legacyPackages."${system}";
          };
          modules = [
            ./1systems/devel.rtinf.net/config.nix
            {
              _module.args.nixinate = {
                host = "devel.rtinf.net";
                sshUser = "root";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = true;
              };
            }
          ];
        };
        safe = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              _module.args.nixinate = {
                host = "safe.user-sites.de";
                sshUser = "root";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = true;
              };
            }
            ./1systems/safe.user-sites.de/config.nix
          ];
        };

        /*
        comms = nixpkgs.lib.nixosSystem rec {
          #system = "aarch64-linux";
          system = "x86_64-linux";
          specialArgs = {
            nixpkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };
          modules = [
            ./1systems/comms.rtinf.net/config.nix
          ];
        };
        */
      }
      // (
        let
          makeTestVM = x: {
            name = "testVM-" + x;
            value = self.nixosConfigurations.${x}.extendModules {modules = [./5pkgs/vm-config.nix];};
          };
        in
          builtins.listToAttrs (builtins.map makeTestVM ["safe" "devel"])
      );
    # adapted from: https://github.com/kmein/niveum
    apps = eachSystem (pkgs: let
      nixinate' = (nixinate.nixinate.${pkgs.system} self).nixinate;
    in
      (builtins.listToAttrs (builtins.map
        (name: {
          name = "nixinate-${name}";
          value = nixinate'.${name};
        })
        (builtins.attrNames nixinate')))
      // {
        deploy = {
          type = "app";
          program = toString (pkgs.writers.writeDash "deploy" ''
            if [ $# -eq 0 ]
            then
              systems='${toString (builtins.filter (x: !(pkgs.lib.hasPrefix "testVM-" x)) (builtins.attrNames self.nixosConfigurations))}'
            else
              systems=$*
            fi
            ${pkgs.parallel}/bin/parallel --line-buffer --tagstring '{}' 'nix run .\?submodules=1\#nixinate-{}' ::: $systems
          '');
        };
      });
    packages = eachSystem (pkgs:
      {
        inherit
          (neovim-flake.lib.neovimConfiguration {
            modules = [
              {
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
                    #crates.enable = true;
                  };
                  go.enable = true;
                  zig.enable = true;
                  python.enable = true;
                  dart.enable = true;
                  elixir.enable = false;
                };

                vim.visuals = {
                  enable = true;
                  nvimWebDevicons.enable = true;
                  scrollBar.enable = true;
                  smoothScroll.enable = true;
                  fidget-nvim.enable = true;
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
                  diffview-nvim.enable = true;
                  motion = {
                    hop.enable = true;
                    leap.enable = true;
                  };
                };

                vim.notes = {
                  obsidian.enable = false; # FIXME neovim fails to build if obsidian is enabled
                  orgmode.enable = false;
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
              }
            ];
            inherit pkgs;
          })
          neovim
          ;

        mango-bin = pkgs.callPackage ./5pkgs/mango.nix {};
        md-dl = nixpkgs-unstable.legacyPackages.${pkgs.system}.callPackage ./5pkgs/md-dl.nix {};
      }
      // pkgs.lib.optionalAttrs (pkgs.system == "x86_64-linux") {
        inherit (nix-gaming.packages.${pkgs.system}) proton-ge;
      });
    devShells =
      eachSystem
      (pkgs: {
        default =
          pkgs.mkShell
          {
            packages = with pkgs; [
              nixpkgs-fmt
              nil
              sumneko-lua-language-server

              # Use `nixos-rebuild build-vm .#${name}` instead
              #(pkgs.writeShellScriptBin "vm-build" ''
              #  export NIXOS_EXTRA_MODULE_PATH=${./.}/5pkgs/vm-config.nix
              #  nixos-rebuild -I "nixos-config=$1" build-vm
              #'')
              (pkgs.writeShellScriptBin "vm-run" ''
                export QEMU_NET_OPTS=net=192.168.76.0/24,dhcpstart=192.168.76.5,hostfwd=tcp::80-:80,hostfwd=tcp::443-:443,hostfwd=tcp::8025-:8025
                ./result/bin/run-*
              '')
            ];
          };
      });
    hydraJobs.nixosConfigurations."x86_64-linux" = let
      mapNameToConfigs = y:
        builtins.listToAttrs (builtins.map
          (x: {
            name = x;
            value = self.nixosConfigurations.${x}.config.system.build.toplevel;
          })
          y);
    in
      mapNameToConfigs ["safe" "devel"];

    formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
    checks = eachSystem (pkgs: {
      formatting = treefmtEval.${pkgs.system}.config.build.check self;
    });
  };
}
