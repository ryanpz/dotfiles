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
vim.fn.setenv('ESCDELAY', '0')
vim.keymap.set('n', '<Leader>f', function()
  local buf = vim.api.nvim_create_buf(false, true)
  local win_width = math.floor(vim.o.columns * 0.4)
  local win_height = math.floor(vim.o.lines * 0.4)
  local win_id = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = win_width - 2,
    height = win_height - 2,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    style = 'minimal',
    border = 'rounded',
  })
  vim.wo[win_id].winhighlight = 'Pmenu:,Normal:Normal'

  local fzf_cmd = 'fzf --keep-right --scheme path --no-height'
  local in_git_repo = vim.system({ 'git', 'rev-parse' }):wait()
  if in_git_repo.code == 0 then
    fzf_cmd = 'git ls-files | ' .. fzf_cmd
  end
  local tmpfile = vim.fn.tempname()
  vim.fn.jobstart(fzf_cmd .. ' > ' .. tmpfile, {
    term = true,
    on_exit = function(_, code, _)
      vim.cmd.bdelete(buf)
      if code ~= 0 then
        vim.fn.delete(tmpfile)
        return
      end

      local fd = io.open(tmpfile, 'r')
      if fd then
        local selected = fd:read()
        fd:close()
        vim.cmd.edit(selected)
      end

      vim.fn.delete(tmpfile)
    end,
  })
  vim.cmd.startinsert()
end)

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
          if vim.g.format_on_save_enabled then
            vim.lsp.buf.format({ bufnr = buf, id = client.id })
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
