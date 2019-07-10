# nvim-luadev

This plugins set up a REPL-like environment for developing lua plugins in Nvim.
The `:Luadev` command will open an scratch window which will show output from executing lua code.

Use the folllowing mappings to execute lua code:

Binding                   | Action
------------------------- | ------
`<Plug>(Luadev-RunLine)`  | Execute the current line
`<Plug>(Luadev-Run)`      | in visual mode: execute visual selection
`<Plug>(Luadev-RunWord)`  | Eval identifier under cursor, including `table.attr`
`<Plug>(Luadev-Complete)` | in insert mode: complete (nested) global table fields

If the code is a expression, it will be evaluated, and the result shown with
`inspect.lua`. Otherwise it will be executed as a block of code. A top-level
`return` will cause the returned value to be inspected. A bare `nil` will not
be shown.

Global `print()` is also redirected to the output buffer, but only when executing
code via this plugin. `require'luadev'.print(...)` can be used to print to the
buffer from some other context.

Planned features:

 - [x] autodetect expression vs statements
 - [x] Fix `inspect.lua` to use `tostring()` on userdata (done on a local copy)
 - [x] completion of global names and table attributes (WIP: basic implementation done)
 - [ ] make `<Plug>(Luadev-Run)` a proper operator
 - [ ] solution for step-wise execution of code with `local` assignments (such
        as a flag to copy local values to an env)
 - [x] tracebacks
 - [ ] interactive debugging
 - [x] debug helpers for async callbacks (WIP)
