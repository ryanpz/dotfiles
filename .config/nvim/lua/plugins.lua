--        --
-- Indent --
--        --
require('guess-indent').setup()

--            --
-- Treesitter --
--            --
require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'bash', 'c', 'cmake', 'comment', 'cpp', 'css', 'dockerfile', 'go',
    'graphql', 'html', 'http', 'java', 'javascript', 'jsdoc', 'json', 'json5',
    'kotlin', 'lua', 'make', 'ninja', 'proto', 'python', 'regex', 'ruby',
    'rust', 'scss', 'svelte', 'toml', 'tsx', 'typescript', 'vim', 'vimdoc',
    'yaml',
  },
  indent = {
    enable = true,
    disable = { 'python', 'c', 'cpp' },
  },
  highlight = {
    enable = true,
  },
})

--           --
-- Fuzzyfind --
--           --
local fzf = require('fzf-lua')

vim.fn.setenv('ESCDELAY', 0)

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

--     --
-- Git --
--     --
local gitsigns_started = false
local gitsigns_setup = function()
  require('gitsigns').setup({
    signcolumn = false,
    on_attach = function(bufnr)
      local gitsigns = require('gitsigns')

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']c', bang = true })
        else
          gitsigns.nav_hunk('next')
        end
      end)

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          gitsigns.nav_hunk('prev')
        end
      end)

      map('n', '<Leader>hs', gitsigns.stage_hunk)
      map('n', '<Leader>hr', gitsigns.reset_hunk)
      map('v', '<Leader>hs', function()
        gitsigns.stage_hunk { vim.fn.line('.'), vim.fn.line('v') }
      end)
      map('v', '<Leader>hr', function()
        gitsigns.reset_hunk { vim.fn.line('.'), vim.fn.line('v') }
      end)
      map('n', '<Leader>hh', gitsigns.preview_hunk)
      map('n', '<Leader>hb', function()
        gitsigns.blame_line { full = true }
      end)
      map('n', '<Leader>tb', gitsigns.toggle_current_line_blame)
      map('n', '<Leader>hd', gitsigns.diffthis)
    end,
  })
end

vim.keymap.set('n', '<Leader>g', function()
  local buf = vim.fn.bufname('*.git*')
  if vim.fn.buflisted(buf) ~= 0 then
    vim.cmd.bdelete('*.git*')
    require('gitsigns').toggle_numhl(false)
    return
  end
  local ok, _ = pcall(vim.cmd.Git)
  if ok then
    if not gitsigns_started then
      gitsigns_setup()
      gitsigns_started = true
    end
    pcall(function()
      require('gitsigns').toggle_numhl(true)
    end)
  end
end, { silent = true })

vim.api.nvim_create_user_command('Difflist', function(opts)
  vim.cmd.Git('difftool --name-only ' .. opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command('Diff', function(opts)
  local branch = 'main'
  if opts.args ~= '' then
    branch = opts.args
  end
  vim.cmd.Gvdiffsplit(branch)
end, { nargs = '?' })

--     --
-- LSP --
--     --
local lspconfig = require('lspconfig')

local servers = {
  ts_ls = {},
  svelte = {},
  clangd = {},
  rust_analyzer = {},
  gopls = {},
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
    local opts = { buffer = args.buf }
    vim.keymap.set('n', 'grd', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gri', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'grt', vim.lsp.buf.type_definition, opts)
    vim.lsp.completion.enable(true, args.data.client_id, args.buf)

    opts.expr = true
    vim.keymap.set({ 'i', 's' }, '<Esc>', function()
      vim.snippet.stop()
      return '<Esc>'
    end, opts)

    if vim.bo.filetype == 'go' then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({ async = false, id = args.data.client_id })
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
