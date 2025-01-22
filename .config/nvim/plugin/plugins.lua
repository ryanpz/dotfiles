for _, v in ipairs({ 'lsp_enabled', 'diagnostics_enabled', 'format_on_save_enabled' }) do
  vim.g[v] = (vim.g[v] ~= false)
end

--          --
-- Closetag --
--          --
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('Closetag', {}),
  pattern = {
    'astro',
    'html',
    'htmlangular',
    'htmldjango',
    'javascript',
    'javascriptreact',
    'markdown',
    'rust',
    'svelte',
    'templ',
    'typescript',
    'typescriptreact',
    'vue',
    'xml',
  },
  callback = function()
    vim.keymap.set('i', '<', function()
      local cursor_pos = vim.api.nvim_win_get_cursor(0)[2]
      local line = vim.api.nvim_get_current_line()

      local tag_candidate = string.match(string.sub(line, 0, cursor_pos), '%<(%w+)[^>/]*%>$')
      if tag_candidate == nil then
        vim.api.nvim_feedkeys('<', 'in', true)
        return
      end

      local closing_tag_after_cursor =
        string.match(string.sub(line, cursor_pos + 1, -1), string.format('^</%s>', tag_candidate))
      if closing_tag_after_cursor then
        vim.api.nvim_feedkeys('<', 'in', true)
        return
      end

      vim.api.nvim_set_current_line(
        string.format(
          '%s</%s>%s',
          string.sub(line, 0, cursor_pos),
          tag_candidate,
          string.sub(line, cursor_pos + 1)
        )
      )
    end, { buffer = true })
  end,
})

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
    'bash',
    'cmake',
    'comment',
    'cpp',
    'css',
    'dockerfile',
    'go',
    'graphql',
    'html',
    'javascript',
    'jsdoc',
    'json',
    'luadoc',
    'make',
    'meson',
    'ninja',
    'proto',
    'python',
    'regex',
    'rust',
    'sql',
    'svelte',
    'toml',
    'tsx',
    'typescript',
    'yaml',
    'zig',
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

local servers = {
  clangd = {
    cmd = { 'clangd' },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
    root_markers = {
      '.clangd',
      '.clang-tidy',
      '.clang-format',
      'compile_commands.json',
      'compile_flags.txt',
      'configure.ac',
      '.git',
    },
    capabilities = {
      textDocument = {
        completion = {
          editsNearCursor = true,
        },
      },
      offsetEncoding = { 'utf-8', 'utf-16' },
    },
  },
  gopls = {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gosum', 'gotmpl' },
    root_dir = function(cb)
      local root = vim.fs.root(0, { 'go.mod' })
      if not root then
        return cb(root)
      end
      local workspace_root = vim.fs.root(root, { 'go.work' })
      if workspace_root then
        return cb(workspace_root)
      end
      return cb(root)
    end,
    settings = { format_on_save = true },
  },
  lua_ls = {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_dir = vim.fs.root(
      0,
      { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', '.git' }
    ),
    on_init = function(client)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc') then
          return
        end
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
      Lua = {
        telemetry = {
          enable = false,
        },
      },
    },
  },
  pyright = {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = {
      'pyproject.toml',
      'setup.py',
      'setup.cfg',
      'requirements.txt',
      'Pipfile',
      'pyrightconfig.json',
      '.git',
    },
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = 'openFilesOnly',
        },
      },
    },
  },
  rust_analyzer = {
    cmd = { 'rust-analyzer' },
    filetypes = { 'rust' },
    root_dir = function(cb)
      local root = vim.fs.root(0, { 'Cargo.toml' })
      if not root then
        return cb(root)
      end

      local out = vim
        .system({ 'cargo', 'metadata', '--no-deps', '--format-version', '1' }, { cwd = root })
        :wait()
      if out.code ~= 0 then
        return cb(root)
      end

      local ok, result = pcall(vim.json.decode, out.stdout)
      if ok and result.workspace_root then
        return cb(result.workspace_root)
      end

      return cb(root)
    end,
    settings = {
      format_on_save = true,
    },
  },
  svelte = {
    cmd = { 'svelteserver', '--stdio' },
    filetypes = { 'svelte' },
    root_markers = { 'package.json', '.git' },
  },
  ts_ls = {
    init_options = { hostInfo = 'neovim' },
    cmd = { 'typescript-language-server', '--stdio' },
    filetypes = {
      'javascript',
      'javascriptreact',
      'javascript.jsx',
      'typescript',
      'typescriptreact',
      'typescript.tsx',
    },
    root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  },
  zls = {
    cmd = { 'zls' },
    filetypes = { 'zig', 'zir' },
    root_markers = { 'build.zig', '.git' },
    settings = { format_on_save = true },
  },
}

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.lsp.completion.enable(true, args.data.client_id, args.buf)

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method('textDocument/formatting') and client.settings.format_on_save then
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

for server, config in pairs(servers) do
  vim.lsp.config(server, config)
  vim.lsp.enable(server)
end
