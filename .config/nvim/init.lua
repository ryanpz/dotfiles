vim.loader.enable()

vim.g.mapleader = ','

vim.o.number = true
vim.o.completeopt = 'menuone'
vim.o.wrap = false
vim.o.mouse = ''
vim.o.laststatus = 3

require('colorscheme')
require('closetag').setup()
require('plugins')
