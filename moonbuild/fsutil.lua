local dir, attributes
do
  local _obj_0 = require('lfs')
  dir, attributes = _obj_0.dir, _obj_0.attributes
end
local gmatch, match, gsub, sub
do
  local _obj_0 = string
  gmatch, match, gsub, sub = _obj_0.gmatch, _obj_0.match, _obj_0.gsub, _obj_0.sub
end
local insert, concat
do
  local _obj_0 = table
  insert, concat = _obj_0.insert, _obj_0.concat
end
local ls
ls = function(d)
  local _accum_0 = { }
  local _len_0 = 1
  for f in dir(d) do
    if f ~= '.' and f ~= '..' then
      _accum_0[_len_0] = f
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local lswithpath
lswithpath = function(d)
  if d == '' then
    return ls('.')
  end
  local _accum_0 = { }
  local _len_0 = 1
  for f in dir(d) do
    if f ~= '.' and f ~= '..' then
      _accum_0[_len_0] = d .. '/' .. f
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local exists
exists = function(f)
  return (attributes(f)) ~= nil
end
local isdir
isdir = function(f)
  local a = attributes(f)
  return a and a.mode == 'directory' or false
end
local mtime
mtime = function(f)
  local a = attributes(f)
  return a and a.modification
end
local matchglob
matchglob = function(str, glob)
  local patt = '^' .. (gsub((gsub(glob, '%*%*', '.*')), '%*', '[^/]*')) .. '$'
  local rst
  if (type(str)) == 'table' then
    local results, i = { }, 1
    for _index_0 = 1, #str do
      local s = str[_index_0]
      rst = (match(s, patt)) and s
      if rst then
        results[i], i = rst, i + 1
      end
    end
    rst = results
  else
    rst = (match(str, patt)) and str
  end
  return rst
end
local wildcard
wildcard = function(glob)
  local parts
  do
    local _accum_0 = { }
    local _len_0 = 1
    for part in gmatch(glob, '[^/]+') do
      _accum_0[_len_0] = part
      _len_0 = _len_0 + 1
    end
    parts = _accum_0
  end
  local absolute = (sub(glob, 1, 1)) == '/'
  for i, part in ipairs(parts) do
    local prevpath = (absolute and '/' or '') .. concat(parts, '/', 1, i - 1)
    local currpath = prevpath .. '/' .. part
    if match(part, '%*%*.*%*%*') then
      error("Two '**' in the same path component in a wildcard")
    end
    if match(part, '%*%*') then
      local prefix = match(currpath, '^(.*)%*%*')
      local suffix = (match(part, '%*%*(.*)$')) .. (i == #parts and '' or ('/' .. concat(parts, '/', i + 1, #parts)))
      local files = lswithpath(prevpath)
      local results = { }
      for _index_0 = 1, #files do
        local file = files[_index_0]
        if matchglob(file, currpath) then
          if i == #parts then
            insert(results, file)
          elseif isdir(file) then
            local _list_0 = wildcard(file .. '/' .. concat(parts, '/', i + 1, #parts))
            for _index_1 = 1, #_list_0 do
              local result = _list_0[_index_1]
              insert(results, result)
            end
          end
        end
        if (matchglob(file, prefix .. '**')) and isdir(file) then
          local _list_0 = wildcard(file .. '/**' .. suffix)
          for _index_1 = 1, #_list_0 do
            local result = _list_0[_index_1]
            insert(results, result)
          end
        end
      end
      return results
    end
    if match(part, '%*') then
      local files = lswithpath(prevpath)
      if i == #parts then
        return matchglob(files, glob)
      end
      local results = { }
      for _index_0 = 1, #files do
        local file = files[_index_0]
        if (matchglob(file, currpath)) and isdir(file) then
          local _list_0 = wildcard(file .. '/' .. concat(parts, '/', i + 1, #parts))
          for _index_1 = 1, #_list_0 do
            local result = _list_0[_index_1]
            insert(results, result)
          end
        end
      end
      return results
    end
  end
  if exists(glob) then
    return {
      glob
    }
  else
    return { }
  end
end
return {
  wildcard = wildcard,
  exists = exists,
  isdir = isdir,
  mtime = mtime
}
