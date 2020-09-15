do

do
local _ENV = _ENV
package.preload[ "moonbuild.fscache" ] = function( ... ) local arg = _G.arg;
local attributes, dir
do
  local _obj_0 = require('lfs')
  attributes, dir = _obj_0.attributes, _obj_0.dir
end
local unpack = unpack or table.unpack
local FROZEN
FROZEN = function() end
local makecached
makecached = function(fn)
  local cache = { }
  local invalidate
  invalidate = function(val)
    cache[val] = nil
  end
  local freeze
  freeze = function(val)
    cache[val] = FROZEN
  end
  local clear
  clear = function()
    cache = { }
  end
  local get
  get = function(val)
    local cached = cache[val]
    if cached ~= FROZEN and cached ~= nil then
      return unpack(cached)
    end
    local ret = {
      fn(val)
    }
    if cached ~= FROZEN then
      cache[val] = ret
    end
    return unpack(ret)
  end
  return setmetatable({
    get = get,
    invalidate = invalidate,
    freeze = freeze,
    clear = clear
  }, {
    __call = function(self, val)
      return get(val)
    end
  })
end
return {
  attributes = makecached(attributes),
  dir = makecached(function(file)
    local _accum_0 = { }
    local _len_0 = 1
    for k in dir(file) do
      _accum_0[_len_0] = k
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)
}

end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.fsutil" ] = function( ... ) local arg = _G.arg;
local dir, attributes
do
  local _obj_0 = require('moonbuild.fscache')
  dir, attributes = _obj_0.dir, _obj_0.attributes
end
local gmatch, match, gsub, sub
do
  local _obj_0 = string
  gmatch, match, gsub, sub = _obj_0.gmatch, _obj_0.match, _obj_0.gsub, _obj_0.sub
end
local insert, remove, concat
do
  local _obj_0 = table
  insert, remove, concat = _obj_0.insert, _obj_0.remove, _obj_0.concat
end
local normalizepath
normalizepath = function(file)
  local parts
  do
    local _accum_0 = { }
    local _len_0 = 1
    for part in gmatch(file, '[^/]+') do
      _accum_0[_len_0] = part
      _len_0 = _len_0 + 1
    end
    parts = _accum_0
  end
  local absolute = (sub(file, 1, 1)) == '/'
  for i = 1, #parts do
    local _continue_0 = false
    repeat
      if parts[i] == '.' then
        remove(parts, i)
        i = i - 1
        _continue_0 = true
        break
      end
      if parts[i] == '..' and i ~= 1 then
        remove(parts, i)
        remove(parts, i - 1)
        i = i - 2
        _continue_0 = true
        break
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  if #parts == 0 then
    return '.'
  else
    return (absolute and '/' or '') .. concat(parts, '/')
  end
end
local ls
ls = function(d)
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = dir(normalizepath(d))
  for _index_0 = 1, #_list_0 do
    local f = _list_0[_index_0]
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
  local _list_0 = dir(normalizepath(d))
  for _index_0 = 1, #_list_0 do
    local f = _list_0[_index_0]
    if f ~= '.' and f ~= '..' then
      _accum_0[_len_0] = d .. '/' .. f
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local exists
exists = function(f)
  return (attributes(normalizepath(f))) ~= nil
end
local isdir
isdir = function(f)
  local a = attributes(normalizepath(f))
  return a and a.mode == 'directory' or false
end
local mtime
mtime = function(f)
  local a = attributes(normalizepath(f))
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
    local currpath = (i == 1 and '' or (prevpath .. '/')) .. part
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
local parentdir
parentdir = function(file)
  return normalizepath(file .. '/..')
end
local freezecache
freezecache = function(file)
  dir.freeze(file)
  dir.freeze(parentdir(file))
  return attributes.invalidate(file)
end
local invalidatecache
invalidatecache = function(file)
  dir.invalidate(file)
  dir.invalidate(parentdir(file))
  return attributes.invalidate(file)
end
local clearcache
clearcache = function()
  dir.clear()
  return attributes.clear()
end
return {
  wildcard = wildcard,
  exists = exists,
  isdir = isdir,
  mtime = mtime,
  normalizepath = normalizepath,
  parentdir = parentdir,
  freezecache = freezecache,
  invalidatecache = invalidatecache,
  clearcache = clearcache
}

end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.stringutil" ] = function( ... ) local arg = _G.arg;
local match, gmatch, sub
do
  local _obj_0 = string
  match, gmatch, sub = _obj_0.match, _obj_0.gmatch, _obj_0.sub
end
local upper, lower
do
  local _obj_0 = string
  upper, lower = _obj_0.upper, _obj_0.lower
end
local GLOB_PATT = '^([^%%]*)%%([^%%]*)$'
local patsubst
patsubst = function(str, pattern, replacement)
  if (type(str)) == 'table' then
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #str do
      local s = str[_index_0]
      _accum_0[_len_0] = patsubst(s, pattern, replacement)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
  local prefix, suffix = match(pattern, GLOB_PATT)
  if not (prefix) then
    return str
  end
  local reprefix, resuffix = match(replacement, GLOB_PATT)
  if not (reprefix) then
    return replacement
  end
  if (sub(str, 1, #prefix)) == prefix and (sub(str, -#suffix)) == suffix then
    return reprefix .. (sub(str, #prefix + 1, -#suffix - 1)) .. resuffix
  end
  return str
end
local splitsp
splitsp = function(str)
  local _accum_0 = { }
  local _len_0 = 1
  for elem in gmatch(str, '%S+') do
    _accum_0[_len_0] = elem
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
return {
  patsubst = patsubst,
  splitsp = splitsp,
  upper = upper,
  lower = lower
}

end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.tableutil" ] = function( ... ) local arg = _G.arg;
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
    if cmp(elem, val) then
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
    if not cmp(elem, val) then
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

end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.util" ] = function( ... ) local arg = _G.arg;
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

end
end

end

local argparse = require('argparse')
require('moonscript')
local loadfile
loadfile = require('moonscript.base').loadfile
local truncate_traceback, rewrite_traceback
do
  local _obj_0 = require('moonscript.errors')
  truncate_traceback, rewrite_traceback = _obj_0.truncate_traceback, _obj_0.rewrite_traceback
end
local trim
trim = require('moonscript.util').trim
local util = require('moonbuild.util')
local freezecache, invalidatecache
do
  local _obj_0 = require('moonbuild.fsutil')
  freezecache, invalidatecache = _obj_0.freezecache, _obj_0.invalidatecache
end
local exists, mtime, run, min, max, first, flatten, match, patsubst, sortedpairs
exists, mtime, run, min, max, first, flatten, match, patsubst, sortedpairs = util.exists, util.mtime, util.run, util.min, util.max, util.first, util.flatten, util.match, util.patsubst, util.sortedpairs
local insert, concat
do
  local _obj_0 = table
  insert, concat = _obj_0.insert, _obj_0.concat
end
local parser = argparse('moonbuild')
parser:argument('targets', "Targets to run"):args('*')
parser:flag('-a --noskip', "Always run targets")
parser:flag('-l --list', "List available targets")
parser:flag('-d --deps', "List targets and their dependancies")
local args = parser:parse()
local loadwithscope
loadwithscope = function(file, scope)
  local fn, err = loadfile(file)
  if not (fn) then
    error(err or "failed to load code")
  end
  local dumped
  dumped, err = string.dump(fn)
  if not (dumped) then
    error(err or "failed to dump function")
  end
  return load(dumped, file, 'b', scope)
end
local pcall
pcall = function(fn, ...)
  local rewrite
  rewrite = function(err)
    local trace = debug.traceback('', 2)
    local trunc = truncate_traceback(trim(trace))
    return (rewrite_traceback(trunc, err)) or trace
  end
  return xpcall(fn, rewrite, ...)
end
local Command
do
  local _class_0
  local _base_0 = {
    __unm = function(self)
      return self:run({
        error = true,
        print = true
      })
    end,
    __len = function(self)
      return self:run({
        error = true
      })
    end,
    __tostring = function(self)
      return self.cmd
    end,
    run = function(self, params)
      return run(self.cmd, self.args, params)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, cmd, ...)
      self.cmd = cmd
      self.args = {
        ...
      }
    end,
    __base = _base_0,
    __name = "Command"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.run = function(self, ...)
    return -self(...)
  end
  Command = _class_0
end
local BuildObject
do
  local _class_0
  local all, skip
  local _base_0 = {
    __tostring = function(self)
      return "Target " .. tostring(self.name) .. " (" .. tostring(concat(self.deps, ', ')) .. ")"
    end,
    build = function(self, name, upper)
      if upper == nil then
        upper = { }
      end
      if skip[name] then
        return 
      end
      if upper[self] then
        error("Cycle detected on " .. tostring(self.name))
      end
      upper = setmetatable({
        [self] = true
      }, {
        __index = upper
      })
      if self.name ~= name then
        local _list_0 = self.deps
        for _index_0 = 1, #_list_0 do
          local dep = _list_0[_index_0]
          self.__class:build((patsubst(name, self.name, dep)), upper)
        end
      else
        local _list_0 = self.deps
        for _index_0 = 1, #_list_0 do
          local dep = _list_0[_index_0]
          self.__class:build(dep, upper)
        end
      end
      if not (self:shouldbuild(name)) then
        return 
      end
      local ins = self.ins
      local outs = self.outs
      if self.name ~= name then
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self.ins
          for _index_0 = 1, #_list_0 do
            local elem = _list_0[_index_0]
            _accum_0[_len_0] = patsubst(name, self.name, elem)
            _len_0 = _len_0 + 1
          end
          ins = _accum_0
        end
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self.outs
          for _index_0 = 1, #_list_0 do
            local elem = _list_0[_index_0]
            _accum_0[_len_0] = patsubst(name, self.name, elem)
            _len_0 = _len_0 + 1
          end
          outs = _accum_0
        end
        print("Building " .. tostring(self.name) .. " as " .. tostring(name))
      else
        print("Building " .. tostring(name))
      end
      for _index_0 = 1, #outs do
        local file = outs[_index_0]
        freezecache(file)
      end
      local ok, err = pcall(function()
        return self.fn({
          ins = ins,
          outs = outs,
          infile = ins[1],
          outfile = outs[1],
          name = name
        })
      end)
      for _index_0 = 1, #outs do
        local file = outs[_index_0]
        invalidatecache(file)
      end
      if not (ok) then
        error("Can't build " .. tostring(self.name) .. ": lua error\n" .. tostring(err))
      end
      for _index_0 = 1, #outs do
        local f = outs[_index_0]
        if not (exists(f)) then
          error("Can't build " .. tostring(self.name) .. ": output file " .. tostring(f) .. " not created")
        end
      end
      skip[name] = true
    end,
    shouldbuild = function(self, name)
      if args.noskip then
        return true
      end
      if #self.ins == 0 or #self.outs == 0 then
        return true
      end
      local ins
      if self.name ~= name then
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self.ins
          for _index_0 = 1, #_list_0 do
            local elem = _list_0[_index_0]
            _accum_0[_len_0] = patsubst(name, self.name, elem)
            _len_0 = _len_0 + 1
          end
          ins = _accum_0
        end
      else
        ins = self.ins
      end
      local itimes
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #ins do
          local f = ins[_index_0]
          _accum_0[_len_0] = mtime(f)
          _len_0 = _len_0 + 1
        end
        itimes = _accum_0
      end
      for i = 1, #self.ins do
        if not (itimes[i]) then
          error("Can't build " .. tostring(self.name) .. ": missing inputs")
        end
      end
      local outs
      if self.name ~= name then
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self.outs
          for _index_0 = 1, #_list_0 do
            local elem = _list_0[_index_0]
            _accum_0[_len_0] = patsubst(name, self.name, elem)
            _len_0 = _len_0 + 1
          end
          outs = _accum_0
        end
      else
        outs = self.outs
      end
      local otimes
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #outs do
          local f = outs[_index_0]
          _accum_0[_len_0] = mtime(f)
          _len_0 = _len_0 + 1
        end
        otimes = _accum_0
      end
      for i = 1, #self.outs do
        if not otimes[i] then
          return true
        end
      end
      return (max(itimes)) > (min(otimes))
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, name, outs, ins, deps, fn)
      if outs == nil then
        outs = { }
      end
      if ins == nil then
        ins = { }
      end
      if deps == nil then
        deps = { }
      end
      if fn == nil then
        fn = function(self) end
      end
      self.name, self.outs, self.ins, self.deps, self.fn = name, outs, ins, deps, fn
      self.skip = false
      if all[self.name] then
        error("Duplicate build name " .. tostring(self.name))
      end
      all[self.name] = self
    end,
    __base = _base_0,
    __name = "BuildObject"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  all = { }
  skip = { }
  self.find = function(self, name)
    local target = all[name]
    if target then
      return target
    end
    for glob, tgt in pairs(all) do
      if match(name, glob) then
        return tgt
      end
    end
    return nil
  end
  self.list = function(self)
    local _tbl_0 = { }
    for name, target in pairs(all) do
      do
        local _tbl_1 = { }
        local _list_0 = target.deps
        for _index_0 = 1, #_list_0 do
          local dep = _list_0[_index_0]
          _tbl_1[dep] = self:find(dep)
        end
        _tbl_0[target] = _tbl_1
      end
    end
    return _tbl_0
  end
  self.build = function(self, name, upper)
    local target = (self:find(name)) or error("No such target: " .. tostring(name))
    return target:build(name, upper)
  end
  BuildObject = _class_0
end
if setfenv then
  error("Need Lua >=5.2")
end
local targets, defaulttarget
local buildscope = {
  default = function(target)
    defaulttarget = target.name
    return target
  end,
  public = function(target)
    insert(targets, target.name)
    return target
  end,
  target = function(name, params)
    local tout = flatten(params.out)
    local tin = flatten(params["in"])
    local tdeps = flatten(params.deps)
    local _list_0 = flatten(params.from)
    for _index_0 = 1, #_list_0 do
      local f = _list_0[_index_0]
      insert(tin, f)
      insert(tdeps, f)
    end
    return BuildObject(name, tout, tin, tdeps, params.fn)
  end,
  Command = Command
}
for k, fn in pairs(util) do
  buildscope[k] = fn
end
setmetatable(buildscope, {
  __index = function(self, k)
    local global = rawget(_G, k)
    if global then
      return global
    end
    return function(...)
      return Command(k, ...)
    end
  end
})
local loadtargets
loadtargets = function()
  targets = { }
  defaulttarget = 'all'
  local file = first({
    'Build.moon',
    'Buildfile.moon',
    'Build',
    'Buildfile'
  }, exists)
  if not (file) then
    error("No Build.moon or Buildfile found")
  end
  local buildfn = loadwithscope(file, buildscope)
  if not (buildfn) then
    error("Failed to load build function")
  end
  return buildfn()
end
local buildtargets
buildtargets = function()
  if #args.targets == 0 then
    BuildObject:build(defaulttarget)
  end
  local _list_0 = args.targets
  for _index_0 = 1, #_list_0 do
    local target = _list_0[_index_0]
    BuildObject:build(target)
  end
end
local ok, err = pcall(loadtargets)
if not (ok) then
  if err then
    io.stderr:write("Error while loading build file: ", err, '\n')
  else
    io.stderr:write("Unknown error\n")
  end
  os.exit(1)
end
if args.list then
  io.write("Available targets:\n")
  io.write("\t" .. tostring(concat(targets, ', ')) .. "\n")
  os.exit(0)
end
if args.deps then
  io.write("Targets:\n")
  for target, deps in sortedpairs(BuildObject:list(), function(a, b)
    return a.name < b.name
  end) do
    io.write("\t" .. tostring(target.name) .. " ")
    if #target.ins == 0 then
      if #target.outs == 0 then
        io.write("[no in/out]")
      else
        io.write("[spontaneous generation]")
      end
    else
      if #target.outs == 0 then
        io.write("[consumer]")
      else
        io.write("(" .. tostring(concat(target.ins, ', ')) .. " -> " .. tostring(concat(target.outs, ', ')) .. ")")
      end
    end
    io.write("\n")
    for name, dep in sortedpairs(deps) do
      io.write("\t\t" .. tostring(name))
      if name ~= dep.name then
        io.write(" (" .. tostring(dep.name) .. ")")
      end
      io.write("\n")
    end
  end
  os.exit(0)
end
return buildtargets()
