local function complete()
  local line = vim.api.nvim_get_current_line()
  local endcol = vim.api.nvim_win_get_cursor(0)[2]
  local text = string.sub(line,1,endcol)
  local x,y,z = string.match(text,"([%.%w%[%]_]-)([:%.%[])([%w_]-)$")
  --require'luadev'.print(x,y,z)
  local status, obj
  if x ~= nil then
    status, obj = pcall(loadstring("return "..x))
  else
    status, obj = true, _G
    y, z = ".", string.match(text,"([%w_]-)$")
  end
  --require'luadev'.print(status,obj,y,z)
  local entries = {}

  if (not status) then
    return
  end

  local function insertify(o)
    for k,_ in pairs(o) do
      if type(k) == "string" and k:sub(1,string.len(z)) == z then
        table.insert(entries,k)
      end
    end
  end

  if type(obj) == 'table' then
    insertify(obj)
  end

  local index = (getmetatable(obj) or {}).__index
  if type(index) == 'table' then
    insertify(index)
  end

  local start = endcol - string.len(z) + 1
  table.sort(entries)
  --require'luadev'.print(vim.inspect(entries))
  -- BUG/REGRESSION?? complete() doesn't respect 'completeopt'
  vim.api.nvim_call_function("complete", {start, entries})
end
-- TODO: luadev should add a command to source a file like this:
--package.loaded['luadev.complete']=complete
return complete
