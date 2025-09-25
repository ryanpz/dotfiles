local palette = {
  black = { gui = '#000000', cterm = 'Black' },
  red = { gui = '#ff6060', cterm = 'Red' },
  green = { gui = '#60ff60', cterm = 'Green' },
  yellow = { gui = '#ffff60', cterm = 'Yellow' },
  blue = { gui = '#00bbff', cterm = 'Blue' },
  cyan = { gui = '#00ffff', cterm = 'Cyan' },
  white = { gui = '#ffffff', cterm = 'White' },
  gray = { gui = '#909090', cterm = 'Gray' },
  orange = { gui = '#ffa500', cterm = 'DarkYellow' },
  menu_bg = { gui = '#333333', cterm = 'Black' },
  menu_bg_alt = { gui = '#202020', cterm = 'Black' },
  highlight_bg = { gui = '#444444', cterm = 'DarkGray' },
  selection_bg = { gui = '#a8a8a8', cterm = 'DarkGray' },
  added_bg = { gui = '#204020', cterm = 'DarkGreen' },
  added_fg = { gui = '#b5f5b5', cterm = 'Black' },
  changed_bg = { gui = '#153850', cterm = 'DarkBlue' },
  changed_fg = { gui = '#a0d0f0', cterm = 'Black' },
  removed_bg = { gui = '#601818', cterm = 'DarkRed' },
  removed_fg = { gui = '#ffb0b0', cterm = 'Black' },
  error_bg = { gui = '#ff0000', cterm = 'DarkRed' },
}

local function hl(fg, bg, opts)
  local result = {}
  if fg then
    result.fg = palette[fg].gui
    result.ctermfg = palette[fg].cterm
  end
  if bg then
    result.bg = palette[bg].gui
    result.ctermbg = palette[bg].cterm
  end
  if opts and opts.sp then
    opts.sp = palette[opts.sp].gui
  end
  return vim.tbl_extend('force', result, opts or {})
end

local groups = {
  ColorColumn = hl(nil, 'highlight_bg'),
  Conceal = hl('gray'),
  CurSearch = hl('black', 'orange'),
  Cursor = { reverse = true },
  lCursor = { link = 'Cursor' },
  CursorIM = { link = 'Cursor' },
  CursorColumn = hl(nil, 'highlight_bg'),
  CursorLine = hl(nil, 'highlight_bg'),
  Directory = { bold = true },
  DiffAdd = hl('added_fg', 'added_bg'),
  DiffChange = hl('changed_fg', 'changed_bg'),
  DiffDelete = hl('removed_fg', 'removed_bg'),
  DiffText = hl('black', 'blue'),
  DiffTextAdd = { link = 'DiffText' },
  TermCursor = { link = 'Cursor' },
  ErrorMsg = hl('white', 'error_bg'),
  Folded = hl('gray'),
  IncSearch = { link = 'CurSearch' },
  Substitute = { link = 'Search' },
  CursorLineNr = { bold = true },
  MatchParen = hl(nil, 'highlight_bg'),
  ModeMsg = { bold = true },
  NormalFloat = hl(nil, 'menu_bg'),
  FloatBorder = hl('gray'),
  FloatTitle = { link = 'Title' },
  FloatFooter = { link = 'FloatTitle' },
  Pmenu = hl(nil, 'menu_bg'),
  PmenuSel = { reverse = true },
  PmenuKind = { link = 'Pmenu' },
  PmenuKindSel = { link = 'PmenuSel' },
  PmenuExtra = { link = 'Pmenu' },
  PmenuExtraSel = { link = 'PmenuSel' },
  PmenuSbar = hl(nil, 'menu_bg_alt'),
  PmenuThumb = hl(nil, 'highlight_bg'),
  PmenuMatch = { bold = true },
  PmenuMatchSel = { bold = true },
  QuickFixLine = hl(nil, 'highlight_bg', { bold = true }),
  Search = { link = 'Visual' },
  SnippetTabstop = hl(nil, 'highlight_bg'),
  SpellBad = hl('red', nil, { underline = true }),
  SpellCap = hl('cyan', nil, { underline = true }),
  SpellLocal = hl('yellow', nil, { underline = true }),
  SpellRare = hl('yellow', nil, { underline = true }),
  StatusLineNC = hl('gray'),
  StatusLineTermNC = { link = 'StatusLineNC' },
  TabLine = { reverse = true },
  TabLineFill = { reverse = true },
  TabLineSel = { bold = true },
  Title = { bold = true },
  Visual = hl('black', 'selection_bg'),
  VisualNOS = { link = 'Visual' },
  WarningMsg = hl('yellow'),
  WildMenu = { link = 'PmenuSel' },
  WinBar = { bold = true },
  WinBarNC = { link = 'WinBar' },
  Underlined = { underline = true },
  Added = hl('green'),
  Changed = hl('cyan'),
  Removed = hl('red'),
  DiagnosticError = hl('red'),
  DiagnosticWarn = hl('orange'),
  DiagnosticInfo = hl('cyan'),
  DiagnosticHint = hl('cyan'),
  DiagnosticOk = hl('green'),
  DiagnosticVirtualTextError = { link = 'DiagnosticError' },
  DiagnosticVirtualTextWarn = { link = 'DiagnosticWarn' },
  DiagnosticVirtualTextInfo = { link = 'DiagnosticInfo' },
  DiagnosticVirtualTextHint = { link = 'DiagnosticHint' },
  DiagnosticVirtualTextOk = { link = 'DiagnosticOk' },
  DiagnosticUnderlineError = hl('red', nil, { sp = 'red', underline = true }),
  DiagnosticUnderlineWarn = hl('orange', nil, { sp = 'orange', underline = true }),
  DiagnosticUnderlineInfo = hl('cyan', nil, { sp = 'cyan', underline = true }),
  DiagnosticUnderlineHint = hl('cyan', nil, { sp = 'cyan', underline = true }),
  DiagnosticUnderlineOk = hl('green', nil, { sp = 'green', underline = true }),
  DiagnosticFloatingError = { link = 'DiagnosticError' },
  DiagnosticFloatingWarn = { link = 'DiagnosticWarn' },
  DiagnosticFloatingInfo = { link = 'DiagnosticInfo' },
  DiagnosticFloatingHint = { link = 'DiagnosticHint' },
  DiagnosticFloatingOk = { link = 'DiagnosticOk' },
  DiagnosticSignError = { link = 'DiagnosticError' },
  DiagnosticSignWarn = { link = 'DiagnosticWarn' },
  DiagnosticSignInfo = { link = 'DiagnosticInfo' },
  DiagnosticSignHint = { link = 'DiagnosticHint' },
  DiagnosticSignOk = { link = 'DiagnosticOk' },
  DiagnosticDeprecated = { strikethrough = true },
  ['@diff.plus'] = { link = 'Added' },
  ['@diff.minus'] = { link = 'Removed' },
  ['@diff.delta'] = { link = 'Changed' },
}

for _, group in ipairs(vim.fn.getcompletion('', 'highlight')) do
  vim.api.nvim_set_hl(0, group, {})
end
vim.g.colors_name = 'rycolor'

for group, parameters in pairs(groups) do
  vim.api.nvim_set_hl(0, group, parameters)
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    if vim.bo.buftype ~= '' then
      return
    end
    vim.cmd.match('ColorColumn /\\%>79v.*\\%<81v/')
  end,
})
