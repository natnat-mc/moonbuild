local wildcard, exists, isdir, mtime
do
  local _obj_0 = require('moonbuild.fsutil')
  wildcard, exists, isdir, mtime = _obj_0.wildcard, _obj_0.exists, _obj_0.isdir, _obj_0.mtime
end
local foreach, first, flatten, exclude, sortedpairs, min, max
do
  local _obj_0 = require('moonbuild.tableutil')
  foreach, first, flatten, exclude, sortedpairs, min, max = _obj_0.foreach, _obj_0.first, _obj_0.flatten, _obj_0.exclude, _obj_0.sortedpairs, _obj_0.min, _obj_0.max
end
local patsubst, splitsp
do
  local _obj_0 = require('moonbuild.stringutil')
  patsubst, splitsp = _obj_0.patsubst, _obj_0.splitsp
end
local insert, concat, sort, pairs
do
  local _obj_0 = require('moonbuild.tableutil')
  insert, concat, sort, pairs = _obj_0.insert, _obj_0.concat, _obj_0.sort, _obj_0.pairs
end
local upper, lower
do
  local _obj_0 = require('moonbuild.stringutil')
  upper, lower = _obj_0.upper, _obj_0.lower
end
local GLOB_PATT = '^([^%%]*)%%([^%%]*)$'
local escapecmdpart
escapecmdpart = function(p)
  if (type(p)) == 'table' then
    if p.raw then
      return p.raw
    end
    return concat((function()
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #p do
        local part = p[_index_0]
        _accum_0[_len_0] = escapecmdpart(part)
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(), ' ')
  end
  if p:match('^[a-zA-Z0-9_./-]+$') then
    return p
  end
  return '"' .. p:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end
local escapecmd
escapecmd = function(c, args)
  if args == nil then
    args = { }
  end
  c = escapecmdpart(c)
  local _list_0 = flatten(args)
  for _index_0 = 1, #_list_0 do
    local a = _list_0[_index_0]
    if a then
      c = c .. (' ' .. escapecmdpart(a))
    end
  end
  return c
end
local run
run = function(c, args, params)
  if params == nil then
    params = { }
  end
  local escaped = escapecmd(c, args)
  if params.print then
    print(escaped)
  end
  local ret, _, code = os.execute(escaped)
  if (type(ret)) == 'number' then
    ret, code = ret == 0, ret
  end
  if params.error and not ret then
    error(tostring(c) .. " failed with code " .. tostring(code))
  end
  return ret, code
end
local popen
popen = function(c, args, mode, params)
  if mode == nil then
    mode = 'r'
  end
  if params == nil then
    params = { }
  end
  local escaped = escapecmd(c, args)
  if params.print then
    print(escaped)
  end
  return io.popen(escaped, mode)
end
local calccdeps
calccdeps = function(infile, includesys)
  if includesys == nil then
    includesys = false
  end
  local data = (popen('cc', {
    includesys and '-M' or '-MM',
    infile
  })):read('*a')
  local rawdeps = data:gsub('\\\n', ''):match(':(.+)')
  local _accum_0 = { }
  local _len_0 = 1
  for dep in rawdeps:gmatch('%S+') do
    if dep ~= infile then
      _accum_0[_len_0] = dep
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local findclib
findclib = function(name, mode)
  if mode == nil then
    mode = 'all'
  end
  local args = {
    name
  }
  if mode == 'all' or mode == 'cc' then
    insert(args, '--cflags')
  end
  if mode == 'all' or mode == 'ld' then
    insert(args, '--libs')
  end
  local _accum_0 = { }
  local _len_0 = 1
  for arg in (popen('pkg-config', args)):read('*a'):gmatch('%S+') do
    _accum_0[_len_0] = arg
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local match
match = function(str, glob)
  local prefix, suffix = glob:match(GLOB_PATT)
  if not (prefix) then
    return str == glob
  end
  if (str:sub(1, #prefix)) == prefix and (str:sub(-#suffix)) == suffix then
    return str:sub(#prefix + 1, -#suffix - 1)
  end
  return false
end
local isglob
isglob = function(glob)
  if glob:match(GLOB_PATT) then
    return true
  else
    return false
  end
end
local env
env = function(key, def)
  return (os.getenv(key)) or def
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
  unpack = unpack,
  wildcard = wildcard,
  mtime = mtime,
  exists = exists,
  isdir = isdir,
  run = run,
  popen = popen,
  calccdeps = calccdeps,
  findclib = findclib,
  patsubst = patsubst,
  splitsp = splitsp,
  upper = upper,
  lower = lower,
  match = match,
  isglob = isglob,
  env = env
}
