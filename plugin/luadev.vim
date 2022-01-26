command! -bar Luadev lua require'luadev'.start()

noremap <Plug>(Luadev-RunLine) <Cmd>lua require'luadev'.exec(vim.api.nvim_get_current_line())<cr>
vnoremap <silent> <Plug>(Luadev-Run) :<c-u>call <SID>luadev_run_operator(v:true)<cr>
nnoremap <silent> <Plug>(Luadev-Run) :<c-u>set opfunc=<SID>luadev_run_operator<cr>g@
noremap <silent> <Plug>(Luadev-RunWord) :<c-u>call luaeval("require'luadev'.exec(_A)", <SID>get_current_word())<cr>
inoremap <Plug>(Luadev-Complete) <Cmd>lua require'luadev.complete'()<cr>

" thanks to @xolox on stackoverflow
function! s:luadev_run_operator(is_op)
    let [lnum1, col1] = getpos(a:is_op ? "'<" : "'[")[1:2]
    let [lnum2, col2] = getpos(a:is_op ? "'>" : "']")[1:2]

    if lnum1 > lnum2
      let [lnum1, col1, lnum2, col2] = [lnum2, col2, lnum1, col1]
    endif

    let lines = getline(lnum1, lnum2)
    if  a:is_op == v:true || lnum1 == lnum2
        let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
        let lines[0] = lines[0][col1 - 1:]
    end
    let lines =  join(lines, "\n")."\n"
    call v:lua.require'luadev'.exec(lines)
endfunction

function! s:get_current_word()
    let isk_save = &isk
    let &isk = '@,48-57,_,192-255,.'
    let word = expand("<cword>")
    let &isk = isk_save
    return word
endfunction


