local insert, remove, concat, sort
do
  local _obj_0 = table
  insert, remove, concat, sort = _obj_0.insert, _obj_0.remove, _obj_0.concat, _obj_0.sort
end
local unpack = unpack or table.unpack
local sortedpairs
sortedpairs = function(table, cmp)
  local keys
  do
    local _accum_0 = { }
    local _len_0 = 1
    for k in pairs(table) do
      _accum_0[_len_0] = k
      _len_0 = _len_0 + 1
    end
    keys = _accum_0
  end
  sort(keys, cmp)
  return coroutine.wrap(function()
    for _index_0 = 1, #keys do
      local key = keys[_index_0]
      coroutine.yield(key, table[key])
    end
  end)
end
local min
min = function(table, cmp)
  if cmp == nil then
    cmp = function(a, b)
      return a < b
    end
  end
  local val = table[1]
  for i = 2, #table do
    local elem = table[i]
    if cmp(val, elem) then
      val = elem
    end
  end
  return val
end
local max
max = function(table, cmp)
  if cmp == nil then
    cmp = function(a, b)
      return a < b
    end
  end
  local val = table[1]
  for i = 2, #table do
    local elem = table[i]
    if not cmp(val, elem) then
      val = elem
    end
  end
  return val
end
local foreach
foreach = function(tab, fn)
  local _accum_0 = { }
  local _len_0 = 1
  for _index_0 = 1, #tab do
    local e = tab[_index_0]
    _accum_0[_len_0] = fn(e)
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local first
first = function(tab, fn)
  for _index_0 = 1, #tab do
    local e = tab[_index_0]
    if fn(e) then
      return e
    end
  end
end
local exclude
exclude = function(tab, ...)
  local i = 1
  while i <= #tab do
    local removed = false
    for j = 1, select('#', ...) do
      if tab[i] == select(j, ...) then
        remove(tab, i)
        removed = true
        break
      end
    end
    if not (removed) then
      i = i + 1
    end
  end
  return tab
end
local flatten
flatten = function(tab)
  if (type(tab)) ~= 'table' then
    return {
      tab
    }
  end
  local out = { }
  for _index_0 = 1, #tab do
    local e = tab[_index_0]
    if (type(e)) == 'table' then
      local _list_0 = flatten(e)
      for _index_1 = 1, #_list_0 do
        local v = _list_0[_index_1]
        insert(out, v)
      end
    else
      insert(out, e)
    end
  end
  return out
end
return {
  min = min,
  max = max,
  foreach = foreach,
  first = first,
  exclude = exclude,
  flatten = flatten,
  sortedpairs = sortedpairs,
  insert = insert,
  remove = remove,
  concat = concat,
  sort = sort,
  unpack = unpack
}
