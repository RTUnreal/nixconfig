local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED by nvim-cmp. get rid of it once we can
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    -- TODO: currently snippets from lsp end up getting prioritized -- stop that!
    { name = 'nvim_lsp' },
  }, {
    { name = 'path' },
  }),
  experimental = {
    ghost_text = true,
  },
})

-- Enable completing paths in :
cmp.setup.cmdline(':', {
  sources = cmp.config.sources({
    { name = 'path' }
  })
})


-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>e', function() vim.diagnostic.open_float() end, opts)
vim.keymap.set('n', '[d', function() vim.diagnostic.goto_prev() end, opts)
vim.keymap.set('n', ']d', function() vim.diagnostic.goto_next() end, opts)
vim.keymap.set('n', '<leader>q', function() vim.diagnostic.setloclist() end, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', function() vim.lsp.buf.declaration() end, bufopts)
    vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, bufopts)
    vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, bufopts)
    vim.keymap.set('n', 'gi', function() vim.lsp.buf.implementation() end, bufopts)
    vim.keymap.set('n', '<C-k>', function() vim.lsp.buf.signature_help() end, bufopts)
    vim.keymap.set('n', '<leader>wa', function() vim.lsp.buf.add_workspace_folder() end, bufopts)
    vim.keymap.set('n', '<leader>wr', function() vim.lsp.buf.remove_workspace_folder() end, bufopts)
    vim.keymap.set('n', '<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<leader>D', function() vim.lsp.buf.type_definition() end, bufopts)
    vim.keymap.set('n', '<leader>rn', function() vim.lsp.buf.rename() end, bufopts)
    vim.keymap.set('n', '<leader>ca', function() vim.lsp.buf.code_action() end, bufopts)
    vim.keymap.set('n', 'gr', function() vim.lsp.buf.references() end, bufopts)
    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end

local lsp_flags = {
    -- This is the default in Nvim 0.7+
    debounce_text_changes = 150,
}

local language_servers = {
    rust_analyzer = { ["rust-analyzer"] = {} },
    lua_ls = {},
    phpactor = {},
    sqlls = {},
    nil_ls = {
        Lua = {
            telemetry = {
                enable = false,
            },
        }
    },
}

for server, settings in pairs(language_servers) do
    require('lspconfig')[server].setup {
        on_attach = on_attach,
        flags = lsp_flags,
        settings = settings,
    }
end
