{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.rtinf.neovim;

  # https://discourse.nixos.org/t/neovim-lua-configuration/22470/5
  neovim-conf = pkgs.vimUtils.buildVimPlugin {
    name = "neovim-conf";
    src = ./conf;
  };
in
{
  options.rtinf.neovim = {
    enable = mkEnableOption (mdDoc "the neovim config");
    enableIDEFeatures = mkEnableOption (mdDoc "the IDE features");
    enableExtendedFeatures = mkEnableOption (mdDoc "the Features, which only make sense in non-specific scenarious");
  };
  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      withRuby = false;
      configure = {
        customRC = ''
          lua require("neovim-conf")
        '';

        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            neovim-conf
            telescope-nvim
            nvim-lspconfig
            nvim-cmp
            vim-fugitive
            undotree
            purescript-vim
            (nvim-treesitter.withPlugins (p: [
              p.bash
              p.c
              p.cmake
              p.dhall
              p.html
              p.javascript
              p.jsdoc
              p.json
              p.lua
              p.markdown
              p.nix
              p.php
              p.phpdoc
              p.python
              p.rust
              p.sql
              p.toml
              p.typescript
            ] ++ optionals cfg.enableExtendedFeatures [
              p.bibtex
              p.hlsl
              p.latex
            ]))
          ];
          opt = [ ];
        };
      };
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };
  };
}
