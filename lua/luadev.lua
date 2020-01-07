local nvimlua_inspect = require'luadev.inspect'

local a = vim.api
if _G.__lua_dev_state == nil then
    _G.__lua_dev_state = {mod = {}}
end
-- TODO: no need for secrecy, just put everything on the "mod" obj
local s = _G.__lua_dev_state
local mod = s.mod

local function create_buf()
  if s.buf ~= nil then
    return
  end
  local buf = a.nvim_create_buf(true,true)
  a.nvim_buf_set_name(buf, "[nvim-lua]")
  s.buf = buf
end

local function open_win()
  if s.win and a.nvim_win_is_valid(s.win) and a.nvim_win_get_buf(s.win) == s.buf then
    return
  end
  create_buf()
  local w0 = a.nvim_get_current_win()
  a.nvim_command("new")
  local w = a.nvim_get_current_win()
  a.nvim_win_set_buf(w,s.buf)
  a.nvim_set_current_win(w0)
  s.win = w
end

local function dosplit(str, delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( str, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( str, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( str, delimiter, from  )
  end
  table.insert( result, string.sub( str, from  ) )
  return result
end

local function splitlines(str)
  return vim.split(str, "\n", true)
end

local function append_buf(lines, hl)
  if s.buf == nil then
    create_buf()
  end
  local l0 = a.nvim_buf_line_count(s.buf)
  if type(lines) == type("") then
    lines = splitlines(lines)
  end

  a.nvim_buf_set_lines(s.buf, l0, l0, true, lines)
  local l1 = a.nvim_buf_line_count(s.buf)
  if hl ~= nil then
    for i = l0, l1-1 do
      a.nvim_buf_add_highlight(s.buf, -1, hl, i, 0, -1)
    end
  end
  local curwin = a.nvim_get_current_win()
  for _,win in ipairs(a.nvim_list_wins()) do
    if a.nvim_win_get_buf(win) == s.buf and win ~= curwin then
      a.nvim_win_set_cursor(win, {l1, 1e9})
    end
  end
  return l0
end

local function luadev_print(...)
  local strs = {}
  local args = {...}
  for i = 1,select('#', ...) do
    strs[i] = tostring(args[i])
  end
  append_buf(table.concat(strs, ' '))
end

local function dedent(str, leave_indent)
  -- find minimum common indent across lines
  local indent = nil
  for line in str:gmatch('[^\n]+') do
    local line_indent = line:match('^%s+') or ''
    if indent == nil or #line_indent < #indent then
      indent = line_indent
    end
  end
  if indent == nil or #indent == 0 then
    -- no minimum common indent
    return str
  end
  local left_indent = (' '):rep(leave_indent or 0)
  -- create a pattern for the indent
  indent = indent:gsub('%s', '[ \t]')
  -- strip it from the first line
  str = str:gsub('^'..indent, left_indent)
  -- strip it from the remaining lines
  str = str:gsub('[\n]'..indent, '\n' .. left_indent)
  return str
end

local function ld_pcall(chunk, ...)
  local coro = coroutine.create(chunk)
  local res = {coroutine.resume(coro, ...)}
  if not res[1] then
    _G._errstack = coro
    -- if the only frame on the traceback is the chunk itself, skip the traceback
    if debug.getinfo(coro, 0,"f").func ~= chunk then
      res[2] = debug.traceback(coro, res[2], 0)
    end
  end
  return unpack(res)
end

local function default_reader(str)
  local chunk, err = loadstring("return \n"..str,"eval")
  if chunk == nil then
    chunk, err = loadstring(str,"exec")
  end
  return chunk, err
end

local function exec(str)
  local reader = mod.reader or default_reader
  local chunk, err = reader(str)
  local inlines = splitlines(dedent(str))
  if inlines[#inlines] == "" then
    inlines[#inlines] = nil
  end
  for i,l in ipairs(inlines) do
    local marker = ((i == 1) and ">") or "."
    inlines[i] = marker.." "..l
  end
  local start = append_buf(inlines)
  for i,_ in ipairs(inlines) do
     a.nvim_buf_add_highlight(s.buf, -1, "Question", start+i-1, 0, 2)
  end
  if chunk == nil then
    append_buf(err,"WarningMsg")
  else
    local oldprint = _G.print
    _G.print = luadev_print
    local st, res = ld_pcall(chunk)
    _G.print = oldprint
    if st == false then
      append_buf(res,"WarningMsg")
    elseif doeval or res ~= nil then
      append_buf(nvimlua_inspect(res))
    end
  end
  append_buf({""})
end

local function start()
  open_win()
end

local function err_wrap(cb)
  return (function (...)
    local res = {ld_pcall(cb, ...)}
    if not res[1] then
      open_win()
      append_buf(res[2],"WarningMsg")
      return nil
    else
      table.remove(res, 1)
      return unpack(res)
    end
  end)
end

local function schedule_wrap(cb)
  return vim.schedule_wrap(err_wrap(cb))
end

local funcs = {
  create_buf=create_buf,
  start=start,
  exec=exec,
  print=luadev_print,
  append_buf=append_buf,
  err_wrap = err_wrap,
  schedule_wrap = schedule_wrap,
}

-- TODO: export abstraction for autoreload
for k,v in pairs(funcs) do
  s.mod[k] = v
end
return s.mod
