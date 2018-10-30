command! Luadev lua require'luadev'.start()

nnoremap <Plug>(Luadev-Run) <Cmd>lua require'luadev'.exec(vim.api.nvim_get_current_line())<cr>
