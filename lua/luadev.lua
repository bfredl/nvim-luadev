local a = vim.api
if _G.__lua_dev_state == nil then
    _G.__lua_dev_state = {}
end
local s = _G.__lua_dev_state

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
 return dosplit(str, "\n")
end

local function append_buf(lines, hl)
  if s.buf == nil then
    return
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

local function luadev_print(x) -- TODO: ...
  local str = tostring(x)
  append_buf({str})
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

local function exec(str,doeval)
  local code = str
  if doeval then
    code = "return \n"..str
  end
  local chunk, err = loadstring(code,"g")
  local inlines = splitlines(dedent(str))
  if inlines[#inlines] == "" then
    inlines[#inlines] = nil
  end
  for i,l in ipairs(inlines) do
    inlines[i] = "> "..l
  end
  append_buf({""})
  local start = append_buf(inlines)
  for i,_ in ipairs(inlines) do
     a.nvim_buf_add_highlight(s.buf, -1, "Question", start+i-1, 0, 2)
  end
  if chunk == nil then
    append_buf({err},"WarningMsg")
  else
    local oldprint = _G.print
    _G.print = luadev_print
    local st, res = pcall(chunk)
    _G.print = oldprint
    if st == false then
      append_buf({res},"WarningMsg")
    elseif doeval or res ~= nil then
      append_buf(require'inspect'(res))
    end
  end
end

local function start()
  create_buf(true)
end

local mod = {
  start=start,
  exec=exec,
  print=luadev_print,
  append_buf=append_buf
}

-- TODO: export abstraction for autoreload
if s.mod == nil then
  s.mod = mod
else
  for k,v in pairs(mod) do
    s.mod[k] = v
  end
end
return s.mod
