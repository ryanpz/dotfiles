vim.opt.termguicolors = true
vim.cmd.colorscheme('vim')

vim.api.nvim_set_hl(0, 'Pmenu', { bg = '#212121' })
vim.api.nvim_set_hl(0, 'PmenuSel', { reverse = true })

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('Overlength', {}),
  pattern = '*',
  callback = function()
    vim.cmd.match('ColorColumn /\\%>79v.*\\%<81v/')
  end,
})
