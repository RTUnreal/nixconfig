require('neovim-conf.lsp')

vim.cmd([[
	autocmd BufRead * autocmd FileType <buffer> ++once if &ft !~# 'commit\|rebase' && line("'\"") > 1 && line("'\"") <= line("$") | exe 'normal! g`"' | endif
]])
--[=[
autocmd = vim.api.nvim_create_autocmd
autocmd(
  "BufRead",
  {
    pattern = "*",
	callback = function()
      autocmd(
        "FileType",
        {
          pattern = "*",
          callback = function()
            if not (vim.bo.ft == 'commit' or vim.bo.ft == 'rebase') and vim.fn.line('\'"') > 1 and vim.fn.line('\'"') <= vim.fn.line('$') then
              vim.cmd([[ normal! g`" ]])
            end
          end
        },
        nil,
        true
      )
    end
  }
)
--]=]

vim.g.mapleader = " "

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.scrolloff = 8
vim.opt.termguicolors = true
vim.opt.colorcolumn = "80"


vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
