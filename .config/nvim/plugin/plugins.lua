for _, v in ipairs({ 'lsp_enabled', 'diagnostics_enabled', 'format_on_save_enabled' }) do
  vim.g[v] = (vim.g[v] ~= false)
end

vim.api.nvim_create_user_command('ToggleDiagnostics', function()
  vim.g.diagnostics_enabled = not vim.g.diagnostics_enabled
  vim.diagnostic.enable(vim.g.diagnostics_enabled)
end, {})

vim.api.nvim_create_user_command('ToggleFormatOnSave', function()
  vim.g.format_on_save_enabled = not vim.g.format_on_save_enabled
end, {})

--              --
-- Fuzzy Finder --
--              --
local project_files = function()
  local files = {}

  local cmds = {
    { 'rg', '--files', '--hidden', '--no-require-git', '--glob', '!.jj/', '--glob', '!.git/' },
    { 'git', 'ls-files', '--cached', '--others', '--exclude-standard', '.' },
    { 'jj', 'file', 'list', '.' },
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

function _G.findfunc(cmd_arg, _cmd_complete)
  local result = vim.uv.fs_stat(cmd_arg)
  if result and result.type ~= 'directory' then
    return { cmd_arg }
  end
  return vim.fn.matchfuzzy(project_files(), cmd_arg)
end
vim.o.findfunc = 'v:lua.findfunc'

vim.keymap.set('n', '<Leader>f', ':find<Space>')

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

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown' },
  callback = function()
    vim.wo[0][0].wrap = true
    vim.wo[0][0].linebreak = true
    vim.wo[0][0].breakindent = true
  end,
})

--            --
-- Formatters --
--            --
local formatters = {
  prettier = {
    filetypes = { 'typescript', 'javascript' },
    executable = 'npx',
    cmd = function(file, config_file)
      return { 'npx', 'prettier', '--config', config_file, '--write', file }
    end,
    config_finder = function(buf, callback)
      vim.system(
        { 'npx', 'prettier', '--find-config-path', vim.api.nvim_buf_get_name(buf) },
        { timeout = 2000 },
        function(out)
          local config = nil
          if out.code == 0 and out.stdout then
            config = vim.trim(out.stdout)
          end
          callback(config)
        end
      )
    end,
  },
  shfmt = {
    filetypes = { 'sh' },
    executable = 'shfmt',
    cmd = function(file)
      return { 'shfmt', '--simplify', '--write', file }
    end,
  },
}

local formatters_running = 0
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    if formatters_running <= 0 then
      return
    end
    vim.wait(10000, function()
      return formatters_running <= 0
    end, 100)
  end,
})

local function setup_format_on_save(name, opts)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = opts.filetypes,
    callback = function(args)
      local buf = args.buf

      if vim.bo[buf].buftype ~= '' then
        return
      end

      if vim.fn.executable(opts.executable) == 0 then
        return
      end
      local file = vim.api.nvim_buf_get_name(buf)

      local function fmt()
        vim.b[buf].formatting = true
        formatters_running = formatters_running + 1

        local cmd = opts.cmd(file, vim.b[buf].format_config)
        vim.system(cmd, { timeout = opts.timeout or 5000 }, function(out)
          vim.b[buf].formatting = false
          formatters_running = formatters_running - 1
          if out.code ~= 0 then
            local error_msg = out.code == 124 and 'Timeout' or out.stderr or 'Unknown error'
            print(string.format('Format failed (%s): %s', name, error_msg))
            return
          end
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.cmd.checktime(buf)
            end
          end)
        end)
      end

      local function create_autocmd()
        vim.api.nvim_create_autocmd('BufWritePost', {
          buffer = buf,
          callback = function()
            if vim.g.format_on_save_enabled and not vim.b[buf].formatting then
              fmt()
            end
          end,
        })
      end

      if not opts.config_finder then
        create_autocmd()
        return
      end

      opts.config_finder(buf, function(config)
        if config then
          vim.b[buf].format_config = config
          vim.schedule(create_autocmd)
        end
      end)
    end,
  })
end

for name, opts in pairs(formatters) do
  setup_format_on_save(name, opts)
end

--             --
-- Diagnostics --
--             --
vim.diagnostic.config({
  underline = false,
  signs = false,
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

vim.api.nvim_create_user_command('D', function()
  vim.diagnostic.setloclist()
end, {})

vim.diagnostic.enable(vim.g.diagnostics_enabled)

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
    settings = { format_on_save = true, format_config_file = '.clang-format' },
  },
  emmylua_ls = {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = { { '.luarc.json', '.emmyrc.json', '.stylua.toml', 'stylua.toml', '.git' } },
    settings = {
      format_on_save = true,
      format_config_file = { '.stylua.toml', 'stylua.toml', '.editorconfig' },
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
  ruff = {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
    settings = { format_on_save = true },
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
  },
  zls = {
    cmd = { 'zls' },
    filetypes = { 'zig', 'zir' },
    root_markers = { { 'build.zig', '.git' } },
    settings = { format_on_save = true },
  },
}

local fmt_group = vim.api.nvim_create_augroup('LspFormatOnSave', {})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local buf = args.buf

    vim.lsp.completion.enable(true, client.id, buf)
    if client.server_capabilities then
      client.server_capabilities.semanticTokensProvider = nil
    end

    if client:supports_method('textDocument/formatting') and client.settings.format_on_save then
      if
        client.settings.format_config_file
        and #vim.fs.find(
            client.settings.format_config_file,
            { upward = true, path = client.root_dir }
          )
          == 0
      then
        return
      end
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = fmt_group,
        buffer = buf,
        callback = function()
          if vim.g.format_on_save_enabled then
            vim.lsp.buf.format({ bufnr = buf, id = client.id })
          end
        end,
      })
    end
  end,
})

vim.api.nvim_create_autocmd('LspDetach', {
  callback = function(args)
    vim.api.nvim_clear_autocmds({
      event = 'BufWritePre',
      buffer = args.buf,
      group = fmt_group,
    })
  end,
})

for server, config in pairs(servers) do
  vim.lsp.config(server, config)
  vim.lsp.enable(server)
end
