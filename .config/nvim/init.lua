vim.loader.enable()

vim.g.mapleader = ','

vim.o.number = true
vim.o.completeopt = 'menuone'
vim.o.wrap = false
vim.o.mouse = ''
vim.o.laststatus = 3

if vim.fn.executable('rg') == 1 then
  vim.o.grepprg = 'rg --vimgrep'
end
