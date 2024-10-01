vim.cmd([[iabbrev <buffer> ife if err != nil {<cr>}<c-o>Oreturn, err<c-o>F,]])
vim.cmd([[iabbrev <buffer> fp fmt.Println()<c-o>i]])
vim.cmd([[iabbrev <buffer> lp log.Println()<c-o>i]])
