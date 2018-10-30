local a = vim.api
if __lua_dev_state == nil then
    __lua_dev_state = {}
end
local s = __lua_dev_state

local function create_buf(window)
  if s.buf ~= nil then
    return
  end
  local w0 = a.nvim_get_current_win()
  a.nvim_command("new")
  local buf = a.nvim_get_current_buf()
  a.nvim_buf_set_option(buf, 'swapfile', false)
  a.nvim_buf_set_option(buf, 'buftype', 'nofile')
  a.nvim_buf_set_name(buf, "[nvim-lua]")

  if not window then
    a.nvim_command("quit")
  end
  a.nvim_set_current_win(w0)
  s.buf = buf
end

local function append_buf(lines, hl)
  local l0 = a.nvim_buf_line_count(s.buf)
  if type(lines) == type("") then
    unimplemented()
  end
  a.nvim_buf_set_lines(s.buf, l0, l0, true, lines)
  if hl ~= nil then
    for i = l0, a.nvim_buf_line_count(s.buf)-1 do
      a.nvim_buf_add_highlight(s.buf, -1, hl, i, 0, -1)
    end
  end
  -- TODO: scroll!
  return l0
end

local function luadev_print(x) -- TODO: ...
  local str = tostring(x)
  append_buf({str})
end

local function exec(str)
  local s, err = loadstring(str,"g")
  if s == nil then
    append_buf({err},"WarningMsg")
  else
    local oldprint = _G.print
    _G.print = luadev_print
    s, err = pcall(s)
    _G.print = oldprint
    if s == false then
      append_buf({err},"WarningMsg")
    end
  end
end

local function start()
  create_buf(true)
end

return {
  start=start,
  exec=exec,
  print=luadev_print,
  append_buf=append_buf
}
