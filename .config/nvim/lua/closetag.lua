-- Auto-closes an XML/HTML tag when the start of the closing tag (`<`) is
-- entered
--
-- Example (cursor denoted as `|`):
-- * input: `<div>|` (press `<`)
-- * output: `<div>|</div>`

local M = {}

local auto_close_tags = function()
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
end

--- @class closetag.Opts
--- @field filetypes? string[] Filetypes to enable closetag for.

--- Configures and enables closetag.
---
--- These are the default values for each field of `opt`:
--- ```lua
--- {
---   filetypes = {
---     'astro',
---     'html',
---     'htmlangular',
---     'htmldjango',
---     'javascript',
---     'javascriptreact',
---     'markdown',
---     'rust',
---     'svelte',
---     'templ',
---     'typescript',
---     'typescriptreact',
---     'vue',
---     'xml',
---   },
--- }
--- ```
---
--- @param opts? closetag.Opts Optional configuration. Leave out a field to use its defaults.
M.setup = function(opts)
  local default_opts = {
    filetypes = {
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
  }
  local cfg = vim.tbl_extend('force', default_opts, opts or {})

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('AutoCloseTags', {}),
    pattern = cfg.filetypes,
    callback = function()
      vim.keymap.set('i', '<', auto_close_tags, { buffer = true })
    end,
  })
end

return M
