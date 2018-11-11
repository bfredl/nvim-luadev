command! Luadev lua require'luadev'.start()

noremap <Plug>(Luadev-RunLine) <Cmd>lua require'luadev'.exec(vim.api.nvim_get_current_line())<cr>
vnoremap <Plug>(Luadev-Run) :<c-u>call luaeval("require'luadev'.exec(_A)", <SID>get_visual_selection())<cr>
noremap <Plug>(Luadev-RunWord) :<c-u>call luaeval("require'luadev'.exec(_A)", <SID>get_current_word())<cr>

" thanks to @xolox on stackoverflow
function! s:get_visual_selection()
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]

    if lnum1 > lnum2
      let [lnum1, col1, lnum2, col2] = [lnum2, col2, lnum1, col1]
    endif

    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")."\n"
endfunction

function! s:get_current_word()
    let isk_save = &isk
    let &isk = '@,48-57,_,192-255,.'
    let word = expand("<cword>")
    let &isk = isk_save
    return word
endfunction


