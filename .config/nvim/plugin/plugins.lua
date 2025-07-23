for _, v in ipairs({ 'lsp_enabled', 'diagnostics_enabled', 'format_on_save_enabled' }) do
  vim.g[v] = (vim.g[v] ~= false)
end

--              --
-- Fuzzy Finder --
--              --
local project_files = function()
  local files = {}

  local cmds = {
    { 'git', 'ls-files', '--cached', '--others', '--exclude-standard' },
    { 'jj', 'file', 'list' },
    { 'find', '.', '-type', 'f' },
  }
  for _, cmd in ipairs(cmds) do
    local out = vim.system(cmd):wait()
    if out.code == 0 and out.stdout then
      files = vim.split(out.stdout, '\n')
      break
    end
  end

  return files
end

vim.api.nvim_create_user_command('F', function(opts)
  local file = ''
  if vim.uv.fs_stat(opts.args) then
    file = opts.args
  else
    file = vim.fn.matchfuzzy(project_files(), opts.args)[1] or ''
  end

  if file == '' then
    print('No matches')
    return
  end

  vim.cmd.edit(file)
end, {
  nargs = 1,
  complete = function(arg_lead)
    if arg_lead == '' then
      return {}
    end
    return vim.fn.matchfuzzy(project_files(), arg_lead)
  end,
})

--           --
-- Filetypes --
--           --
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'svelte' },
  callback = function()
    vim.cmd.runtime({ 'syntax/astro.vim', bang = true })
    vim.cmd.runtime({ 'indent/html.vim', bang = true })
  end,
})

--             --
-- Diagnostics --
--             --
vim.diagnostic.config({
  underline = false,
  signs = {
    text = {
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
  },
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({
        bufnr = bufnr,
        scope = 'cursor',
        focus = false,
      })
    end,
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
      {
        '.clangd',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        'configure.ac',
        '.git',
      },
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
    root_dir = function(buf, on_dir)
      local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
      local out = vim.system({ 'go', 'env', '-json', 'GOMOD' }, { cwd = cwd }):wait()
      if out.code ~= 0 or not out.stdout then
        return
      end

      local ok, result = pcall(vim.json.decode, out.stdout)
      if ok and result.GOMOD ~= '/dev/null' then
        on_dir(vim.fs.dirname(result.GOMOD))
      end
    end,
    settings = { format_on_save = true },
  },
  emmylua_ls = {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = { { '.luarc.json', '.emmyrc.json', '.stylua.toml', 'stylua.toml', '.git' } },
  },
  pyright = {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = {
      {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        'pyrightconfig.json',
        '.git',
      },
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
    root_dir = function(buf, on_dir)
      local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
      local out = vim
        .system({ 'cargo', 'metadata', '--no-deps', '--format-version', '1' }, { cwd = cwd })
        :wait()
      if out.code ~= 0 or not out.stdout then
        return
      end

      local ok, result = pcall(vim.json.decode, out.stdout)
      if ok and result.workspace_root then
        on_dir(result.workspace_root)
      end
    end,
    settings = { format_on_save = true },
  },
  svelte = {
    cmd = { 'svelteserver', '--stdio' },
    filetypes = { 'svelte' },
    root_markers = { { 'package.json', '.git' } },
    settings = { format_on_save = true },
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
    root_markers = { { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' } },
    settings = { format_on_save = true },
    on_init = function(client)
      if not client.settings.format_on_save then
        return
      end

      local has_prettier_config = #vim.fn.glob(client.root_dir .. '/.prettierrc*', true, true) > 0
      if not has_prettier_config then
        client.settings.format_on_save = false
        return
      end

      client.settings.use_prettier = true
    end,
  },
  zls = {
    cmd = { 'zls' },
    filetypes = { 'zig', 'zir' },
    root_markers = { { 'build.zig', '.git' } },
    settings = { format_on_save = true },
  },
}

local function prettier_fmt(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  vim.system({ 'npx', 'prettier', '--write', file }, {}, function(out)
    if out.code ~= 0 then
      print('Error formatting with prettier')
      return
    end
    vim.schedule(function()
      vim.cmd.checktime(buf)
    end)
  end)
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local buf = args.buf

    vim.lsp.completion.enable(true, client.id, buf)
    if client.server_capabilities then
      client.server_capabilities.semanticTokensProvider = nil
    end

    if client:supports_method('textDocument/formatting') and client.settings.format_on_save then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = buf,
        callback = function()
          if not vim.g.format_on_save_enabled then
            return
          end

          if client.settings.use_prettier then
            prettier_fmt(buf)
            return
          end
          vim.lsp.buf.format({ bufnr = buf, id = client.id })
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
