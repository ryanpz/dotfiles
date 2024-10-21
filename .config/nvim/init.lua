vim.loader.enable()

vim.g.mapleader = ','

vim.opt.number = true
vim.opt.completeopt = 'menuone'
vim.opt.wrap = false
vim.opt.mouse = ''
vim.opt.laststatus = 3

require('colorscheme')
require('closetag').setup()
require('plugins')
