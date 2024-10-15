--              --
-- Guess-Indent --
--              --
require('guess-indent').setup()

--          --
-- Fugitive --
--          --
vim.keymap.set('n', '<Leader>g', function()
  if vim.fn.FugitiveGitDir() == '' then
    return
  end

  local buf = vim.fn.bufnr('^fugitive://*/$')
  if vim.fn.buflisted(buf) ~= 0 then
    vim.cmd.bdelete(buf)
    return
  end

  vim.cmd.Git()
end)

--     --
-- Fzf --
--     --
local fzf = require('fzf-lua')
vim.fn.setenv('ESCDELAY', '0')

fzf.setup({
  files = {
    previewer = false,
    actions = {
      ['ctrl-g'] = false,
    },
  },
  winopts = {
    height = 0.4,
    width = 0.4,
    row = 0.5,
    col = 0.5,
  },
  fzf_opts = {
    ['--keep-right'] = '',
    ['--no-separator'] = '',
  },
  fzf_colors = true,
})

vim.keymap.set('n', '<Leader>p', fzf.files)

--            --
-- Treesitter --
--            --
require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'bash', 'c', 'cmake', 'comment', 'cpp', 'css', 'dockerfile', 'go',
    'graphql', 'html', 'javascript', 'jsdoc', 'json', 'lua', 'luadoc', 'make',
    'markdown', 'markdown_inline', 'meson', 'ninja', 'proto', 'python',
    'query', 'regex', 'rust', 'sql', 'svelte', 'toml', 'tsx', 'typescript',
    'vim', 'vimdoc', 'yaml', 'zig',
  },
  indent = {
    enable = true,
    disable = { 'python', 'c', 'cpp' },
  },
  highlight = {
    enable = true,
  },
})

--     --
-- LSP --
--     --
local lspconfig = require('lspconfig')

local servers = {
  ts_ls = {},
  svelte = {},
  clangd = {},
  rust_analyzer = { settings = { format_on_save = true } },
  gopls = { settings = { format_on_save = true } },
  pyright = { autostart = false },
  lua_ls = {
    on_init = function(client)
      local path = client.workspace_folders[1].name
      if vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc') then
        return
      end
      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
        },
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME,
          },
        },
      })
    end,
    settings = {
      Lua = {},
    },
  },
}

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.lsp.completion.enable(true, args.data.client_id, args.buf)

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.supports_method('textDocument/formatting') and client.settings.format_on_save then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
        end,
      })
    end
  end,
})

vim.diagnostic.config({
  virtual_text = false,
  underline = false,
  jump = { float = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
    },
    texthl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
    },
  },
})

for server, server_opts in pairs(servers) do
  lspconfig[server].setup(server_opts)
end
