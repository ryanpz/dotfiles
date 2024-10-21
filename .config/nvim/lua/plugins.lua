for _, v in ipairs({ 'lsp_enabled', 'diagnostics_enabled', 'format_on_save_enabled' }) do
  vim.g[v] = (vim.g[v] ~= false)
end

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

  local buf = vim.fn.bufnr('^fugitive://*')
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

vim.keymap.set('n', '<Leader>f', fzf.files)

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

--             --
-- Diagnostics --
--             --
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

vim.diagnostic.enable(vim.g.diagnostics_enabled)

vim.api.nvim_create_user_command('ToggleDiagnostics', function()
  vim.g.diagnostics_enabled = not vim.g.diagnostics_enabled
  vim.diagnostic.enable(vim.g.diagnostics_enabled)
end, {})

--     --
-- LSP --
--     --
if not vim.g.lsp_enabled then
  return
end

local lspconfig = require('lspconfig')

local servers = {
  clangd = {},
  gopls = { settings = { format_on_save = true } },
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
  pyright = {},
  rust_analyzer = { settings = { format_on_save = true } },
  svelte = {},
  ts_ls = {},
  zls = { settings = { format_on_save = true } },
}

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.lsp.completion.enable(true, args.data.client_id, args.buf)

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.supports_method('textDocument/formatting') and client.settings.format_on_save then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = args.buf,
        callback = function()
          if vim.g.format_on_save_enabled then
            vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
          end
        end,
      })
    end
  end,
})

vim.api.nvim_create_user_command('ToggleFormatOnSave', function()
  vim.g.format_on_save_enabled = not vim.g.format_on_save_enabled
end, {})

for server, opts in pairs(servers) do
  lspconfig[server].setup(opts)
end
