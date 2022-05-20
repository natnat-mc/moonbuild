do
local _ENV = _ENV
package.preload[ "moonbuild._" ] = function( ... ) local arg = _G.arg;
local gmatch, match, gsub
do
  local _obj_0 = string
  gmatch, match, gsub = _obj_0.gmatch, _obj_0.match, _obj_0.gsub
end
local insert, remove, concat, sub, sort
do
  local _obj_0 = table
  insert, remove, concat, sub, sort = _obj_0.insert, _obj_0.remove, _obj_0.concat, _obj_0.sub, _obj_0.sort
end
local _fs = require('moonbuild._fs')
local _cmd = require('moonbuild._cmd')
local _util = require('moonbuild._util')
local _common = require('moonbuild._common')
local _ = { }
for k, lib in pairs({
  _fs = _fs,
  _cmd = _cmd,
  _util = _util,
  _common = _common
}) do
  _[k] = lib
  local _list_0 = lib()
  for _index_0 = 1, #_list_0 do
    local n = _list_0[_index_0]
    _[n] = lib[n]
  end
end
return _
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._cmd" ] = function( ... ) local arg = _G.arg;
local parseargs, escape
do
  local _obj_0 = require('moonbuild._cmd.common')
  parseargs, escape = _obj_0.parseargs, _obj_0.escape
end
local ok, cmd, backend = false, nil, nil
if not (ok) then
  ok, cmd = pcall(function()
    return require('moonbuild._cmd.posix')
  end)
  backend = 'posix'
end
if not (ok) then
  ok, cmd = pcall(function()
    return require('moonbuild._cmd.lua')
  end)
  backend = 'lua'
end
if not (ok) then
  error("unable to load any cmd library, tried luaposix and posix commands")
end
do
  local _tbl_0 = { }
  for k, v in pairs(cmd) do
    _tbl_0[k] = v
  end
  cmd = _tbl_0
end
cmd.backend = backend
cmd.parseargs = parseargs
cmd.escape = escape
local _cmd = cmd.cmd
local _cmdrst = cmd.cmdrst
cmd.cmdline = function(cmdline)
  return _cmd(parseargs(cmdline))
end
cmd.cmdlinerst = function(cmdline)
  return _cmdrst(parseargs(cmdline))
end
return setmetatable(cmd, {
  __call = function(self)
    return {
      'cmd',
      'cmdrst',
      'cmdline',
      'cmdlinerst',
      'sh'
    }
  end
})
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._cmd.common" ] = function( ... ) local arg = _G.arg;
local gsub, sub, match
do
  local _obj_0 = string
  gsub, sub, match = _obj_0.gsub, _obj_0.sub, _obj_0.match
end
local concat
concat = table.concat
local specialchars = {
  ['\"'] = '\\\"',
  ['\\'] = '\\\\',
  ['\''] = '\\\'',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t'
}
local replacespecialchar
replacespecialchar = function(c)
  return specialchars[c] or c
end
local escape
escape = function(arg)
  if match(arg, "^[a-zA-Z0-9_.-]+$") then
    return arg
  end
  return '"' .. (gsub(arg, "([\"\\\n\r\t])", replacespecialchar)) .. '"'
end
local parseargs
parseargs = function(argstr)
  local state = 'normal'
  local current, ci = { }, 1
  local args, ai = { }, 1
  local c = nil
  local i = 0
  local running = true
  local add
  add = function()
    current[ci], ci = c, ci + 1
  end
  local push
  push = function()
    if ci ~= 1 then
      args[ai], ai, current, ci = (concat(current)), ai + 1, { }, 1
    end
  end
  local addv
  addv = function(v)
    current[ci], ci = v, ci + 1
  end
  local fail
  fail = function(msg)
    return error("failed to parse: " .. tostring(msg) .. " in state " .. tostring(state) .. " at pos " .. tostring(i), 2)
  end
  local finish
  finish = function()
    running = false
  end
  local EOF = ''
  while running do
    i = i + 1
    c = sub(argstr, i, i)
    local _exp_0 = state
    if 'normal' == _exp_0 then
      local _exp_1 = c
      if '\"' == _exp_1 then
        state = 'doublequote'
      elseif '\'' == _exp_1 then
        state = 'singlequote'
      elseif ' ' == _exp_1 then
        push()
      elseif '\n' == _exp_1 then
        push()
      elseif '\t' == _exp_1 then
        push()
      elseif '\\' == _exp_1 then
        state = 'backslashnormal'
      elseif EOF == _exp_1 then
        push()
        finish()
      else
        add()
      end
    elseif 'doublequote' == _exp_0 then
      local _exp_1 = c
      if '\"' == _exp_1 then
        state = 'normal'
      elseif '\\' == _exp_1 then
        state = 'backslashdoublequote'
      elseif EOF == _exp_1 then
        fail("unexpected EOF")
      else
        add()
      end
    elseif 'singlequote' == _exp_0 then
      local _exp_1 = c
      if '\'' == _exp_1 then
        state = 'normal'
      elseif EOF == _exp_1 then
        fail("unexpected EOF")
      else
        add()
      end
    elseif 'backslashnormal' == _exp_0 then
      local _exp_1 = c
      if '\n' == _exp_1 then
        state = 'normal'
      elseif EOF == _exp_1 then
        fail("unexpected EOF")
      else
        add()
        state = 'normal'
      end
    elseif 'backslashdoublequote' == _exp_0 then
      local _exp_1 = c
      if '$' == _exp_1 then
        add()
        state = 'doublequote'
      elseif '`' == _exp_1 then
        add()
        state = 'doublequote'
      elseif '\"' == _exp_1 then
        add()
        state = 'doublequote'
      elseif '\\' == _exp_1 then
        add()
        state = 'doublequote'
      elseif '\n' == _exp_1 then
        state = 'doublequote'
      elseif EOF == _exp_1 then
        fail("unexpected EOF")
      else
        addv('\\')
        add()
        state = 'doublequote'
      end
    end
  end
  return args
end
return {
  escape = escape,
  parseargs = parseargs
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._cmd.lua" ] = function( ... ) local arg = _G.arg;
local escape
escape = require('moonbuild._cmd.common').escape
local flatten
flatten = require('moonbuild._common').flatten
local execute
execute = require('moonbuild.compat.execute').execute
local popen
popen = io.popen
local concat
concat = table.concat
local cmdline
cmdline = function(...)
  return concat((function(...)
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = flatten(...)
    for _index_0 = 1, #_list_0 do
      local arg = _list_0[_index_0]
      _accum_0[_len_0] = escape(arg)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(...), ' ')
end
local cmd
cmd = function(...)
  local ok, ret, code = execute(cmdline(...))
  if not (ok) then
    return error("command " .. tostring(first(...)) .. " exited with " .. tostring(code) .. " (" .. tostring(ret) .. ")")
  end
end
local cmdrst
cmdrst = function(...)
  local fd, err = popen(cmdline(...))
  if not (fd) then
    error(err)
  end
  local data = fd:read('*a')
  fd:close()
  return data
end
local sh
sh = function(cli)
  local ok, ret, code = execute(cli)
  if not (ok) then
    return error("command '" .. tostring(cli) .. "' exited with " .. tostring(code) .. " (" .. tostring(ret) .. ")")
  end
end
return {
  cmd = cmd,
  cmdrst = cmdrst,
  sh = sh
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._cmd.posix" ] = function( ... ) local arg = _G.arg;
local spawn
spawn = require('posix').spawn
local fork, execp, pipe, dup2, _exit, close
do
  local _obj_0 = require('posix.unistd')
  fork, execp, pipe, dup2, _exit, close = _obj_0.fork, _obj_0.execp, _obj_0.pipe, _obj_0.dup2, _obj_0._exit, _obj_0.close
end
local fdopen
fdopen = require('posix.stdio').fdopen
local wait
wait = require('posix.sys.wait').wait
local flatten, first
do
  local _obj_0 = require('moonbuild._common')
  flatten, first = _obj_0.flatten, _obj_0.first
end
local remove
remove = table.remove
local cmd
cmd = function(...)
  local code, ty = spawn(flatten(...))
  if ty ~= 'exited' or code ~= 0 then
    return error("command " .. tostring(first(...)) .. " " .. tostring(ty) .. " with code " .. tostring(code))
  end
end
local cmdrst
cmdrst = function(...)
  local rd, wr = pipe()
  local pid, err = fork()
  if pid == 0 then
    dup2(wr, 1)
    close(rd)
    local args = flatten(...)
    local c = remove(args, 1)
    execp(c, args)
    return _exit(1)
  end
  if pid == nil then
    close(rd)
    close(wr)
    error("command " .. tostring(first(...)) .. " failed to start: couldn't fork(): " .. tostring(err))
  end
  close(wr)
  local fd = fdopen(rd, 'r')
  local data = fd:read('*a')
  fd:close()
  close(rd)
  local _, ty, code = wait(pid)
  if ty ~= 'exited' or code ~= 0 then
    error("command " .. tostring(first(...)) .. " " .. tostring(ty) .. " with code " .. tostring(code))
  end
  return data
end
local sh
sh = function(cli)
  return cmd('sh', '-c', cli)
end
return {
  cmd = cmd,
  cmdrst = cmdrst,
  sh = sh
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._common" ] = function( ... ) local arg = _G.arg;
local sort, concat
do
  local _obj_0 = table
  sort, concat = _obj_0.sort, _obj_0.concat
end
local huge
huge = math.huge
local match, sub
do
  local _obj_0 = string
  match, sub = _obj_0.match, _obj_0.sub
end
local common = { }
local flatten
flatten = function(list, ...)
  if (select('#', ...)) ~= 0 then
    return flatten({
      list,
      ...
    })
  end
  local t = type(list)
  local _exp_0 = t
  if 'nil' == _exp_0 then
    return { }
  elseif 'string' == _exp_0 then
    return {
      list
    }
  elseif 'number' == _exp_0 then
    return {
      tostring(list)
    }
  elseif 'boolean' == _exp_0 then
    return {
      list
    }
  elseif 'table' == _exp_0 then
    local keys
    do
      local _accum_0 = { }
      local _len_0 = 1
      for k in pairs(list) do
        _accum_0[_len_0] = k
        _len_0 = _len_0 + 1
      end
      keys = _accum_0
    end
    sort(keys)
    local elements, i = { }, 1
    for _index_0 = 1, #keys do
      local k = keys[_index_0]
      if (type(k)) == 'number' then
        local _list_0 = (flatten(list[k]))
        for _index_1 = 1, #_list_0 do
          local e = _list_0[_index_1]
          elements[i], i = e, i + 1
        end
      else
        return {
          list
        }
      end
    end
    return setmetatable(elements, {
      __tostring = function(self)
        return concat(self, ' ')
      end
    })
  else
    return error("can't flatten elements of type " .. tostring(t))
  end
end
local first
first = function(list, ...)
  local t = type(list)
  local _exp_0 = t
  if 'nil' == _exp_0 then
    if (select('#', ...)) == 0 then
      return nil
    else
      return first(...)
    end
  elseif 'string' == _exp_0 then
    return list
  elseif 'number' == _exp_0 then
    return tostring(list)
  elseif 'boolean' == _exp_0 then
    return list
  elseif 'table' == _exp_0 then
    local min = huge
    for k in pairs(list) do
      if (type(k)) == 'number' then
        if k < min then
          min = k
        end
      else
        return list
      end
    end
    return first(list[min])
  else
    return error("can't find first of type " .. tostring(t))
  end
end
local foreach
foreach = function(list, fn)
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = flatten(list)
  for _index_0 = 1, #_list_0 do
    local v = _list_0[_index_0]
    _accum_0[_len_0] = fn(v)
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local filter
filter = function(list, fn)
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = flatten(list)
  for _index_0 = 1, #_list_0 do
    local v = _list_0[_index_0]
    if fn(v) then
      _accum_0[_len_0] = v
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local includes
includes = function(list, v)
  if list == v then
    return true
  end
  if (type(list)) == 'table' then
    for k, e in pairs(list) do
      if (type(k)) == 'number' then
        if includes(e, v) then
          return true
        end
      end
    end
  end
  if (type(list)) == 'number' then
    return (tostring(list)) == (tostring(v))
  end
  return false
end
local patget
patget = function(s, pat)
  local prefix, suffix = match(pat, '^(.*)%%(.*)$')
  if not (prefix) then
    return s == pat and s or nil
  end
  if (sub(s, 1, #prefix)) == prefix and (suffix == '' or (sub(s, -#suffix)) == suffix) then
    return sub(s, #prefix + 1, -#suffix - 1)
  else
    return nil
  end
end
local patset
patset = function(s, rep)
  local prefix, suffix = match(rep, '^(.*)%%(.*)$')
  if prefix then
    return prefix .. s .. suffix
  else
    return rep
  end
end
local patsubst
patsubst = function(s, pat, rep)
  local prefix, suffix = match(pat, '^(.*)%%(.*)$')
  local rprefix, rsuffix = match(rep, '^(.*)%%(.*)$')
  local t = type(s)
  local f = false
  if t == 'nil' then
    return nil
  end
  if t == 'number' then
    t = 'string'
    s = tostring(s)
  end
  if t == 'string' then
    t = 'table'
    s = {
      s
    }
    f = true
  end
  if t ~= 'table' then
    error("can't substitute patterns on type " .. tostring(t))
  end
  local r, i = { }, 1
  local _list_0 = flatten(s)
  for _index_0 = 1, #_list_0 do
    local s = _list_0[_index_0]
    if not prefix then
      if s == pat then
        if rprefix then
          r[i], i = rprefix .. s .. rsuffix, i + 1
        else
          r[i], i = rep, i + 1
        end
      end
    elseif (sub(s, 1, #prefix)) == prefix and (suffix == '' or (sub(s, -#suffix)) == suffix) then
      if rprefix then
        r[i], i = rprefix .. (sub(s, #prefix + 1, -#suffix - 1)) .. rsuffix, i + 1
      else
        r[i], i = rep, i + 1
      end
    end
  end
  return f and r[1] or r
end
local exclude
exclude = function(list, ...)
  local exclusions = flatten(...)
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = flatten(list)
  for _index_0 = 1, #_list_0 do
    local v = _list_0[_index_0]
    if not includes(exclusions, v) then
      _accum_0[_len_0] = v
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local min
min = function(list)
  local m = list[1]
  for i = 2, #list do
    local e = list[i]
    if e < m then
      m = e
    end
  end
  return m
end
local max
max = function(list)
  local m = list[1]
  for i = 2, #list do
    local e = list[i]
    if e > m then
      m = e
    end
  end
  return m
end
local minmax
minmax = function(list)
  local m = list[1]
  local M = list[1]
  for i = 2, #list do
    local e = list[i]
    if e < m then
      m = e
    end
    if e > M then
      M = e
    end
  end
  return m, M
end
common.flatten = flatten
common.first = first
common.foreach = foreach
common.filter = filter
common.includes = includes
common.patget = patget
common.patset = patset
common.patsubst = patsubst
common.exclude = exclude
common.min = min
common.max = max
common.minmax = minmax
return setmetatable(common, {
  __call = function(self)
    local _accum_0 = { }
    local _len_0 = 1
    for k in pairs(common) do
      _accum_0[_len_0] = k
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
})
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._fs" ] = function( ... ) local arg = _G.arg;
local remove, concat
do
  local _obj_0 = table
  remove, concat = _obj_0.remove, _obj_0.concat
end
local gmatch, match, gsub, sub
do
  local _obj_0 = string
  gmatch, match, gsub, sub = _obj_0.gmatch, _obj_0.match, _obj_0.gsub, _obj_0.sub
end
local ok, fs, backend = false, nil, nil
if not (ok) then
  ok, fs = pcall(function()
    return require('moonbuild._fs.posix')
  end)
  backend = 'posix'
end
if not (ok) then
  ok, fs = pcall(function()
    return require('moonbuild._fs.lfs')
  end)
  backend = 'lfs'
end
if not (ok) then
  ok, fs = pcall(function()
    return require('moonbuild._fs.cmd')
  end)
  backend = 'cmd'
end
if not (ok) then
  error("unable to load any fs library, tried luaposix, luafilesystem and posix commands")
end
local DISABLED = (function()
  return DISABLED
end)
local NIL = (function()
  return NIL
end)
local cacheenabled = true
local caches = { }
local clearcache
clearcache = function()
  for k, v in pairs(caches) do
    v.clearcache()
  end
end
local clearentry
clearentry = function(entry)
  for k, v in pairs(caches) do
    v.clearentry(entry)
  end
end
local disableentry
disableentry = function(entry)
  for k, v in pairs(caches) do
    v.disableentry(entry)
  end
end
local disablecache
disablecache = function()
  cacheenabled = false
end
local enablecache
enablecache = function()
  cacheenabled = true
end
local withcache
withcache = function(fn)
  local opts = { }
  opts.cache = { }
  opts.clearcache = function()
    opts.cache = { }
  end
  opts.clearentry = function(entry)
    opts.cache[entry] = nil
  end
  opts.disableentry = function(entry)
    opts.cache[entry] = DISABLED
  end
  caches[fn] = opts
  return setmetatable(opts, {
    __call = function(self, arg)
      if not (cacheenabled) then
        return fn(arg)
      end
      local cached = opts.cache[arg]
      if cached == DISABLED then
        return fn(arg)
      end
      if cached == NIL then
        return nil
      end
      if cached ~= nil then
        return cached
      end
      cached = fn(arg)
      opts.cache[arg] = cached
      if cached == nil then
        opts.cache[arg] = NIL
      end
      return cached
    end
  })
end
fs = {
  dir = withcache(fs.dir),
  attributes = withcache(fs.attributes),
  mkdir = fs.mkdir
}
local attributes, dir, mkdir
attributes, dir, mkdir = fs.attributes, fs.dir, fs.mkdir
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
  local i = 1
  while i <= #parts do
    local _continue_0 = false
    repeat
      if parts[i] == '.' then
        remove(parts, i)
        _continue_0 = true
        break
      end
      if parts[i] == '..' and i ~= 1 and parts[i - 1] ~= '..' then
        remove(parts, i)
        remove(parts, i - 1)
        i = i - 1
        _continue_0 = true
        break
      end
      i = i + 1
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  if #parts == 0 then
    return absolute and '/' or '.'
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
local matchglob
matchglob = function(str, glob)
  glob = gsub(glob, '[%[%]%%+.?-]', function(self)
    return '%' .. self
  end)
  local patt = '^' .. (gsub(glob, '%*%*?', function(self)
    return self == '**' and '.*' or '[^/]*'
  end)) .. '$'
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
local exists
exists = function(f)
  return (attributes(normalizepath(f))) ~= nil
end
local isdir
isdir = function(f)
  return ((attributes(normalizepath(f))) or { }).mode == 'directory'
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
      if not (exists(prevpath)) then
        return { }
      end
      local files = lswithpath(prevpath)
      local results, ri = { }, 1
      for _index_0 = 1, #files do
        local file = files[_index_0]
        if matchglob(file, currpath) then
          if i == #parts then
            results[ri], ri = file, ri + 1
          elseif isdir(file) then
            local _list_0 = wildcard(file .. '/' .. concat(parts, '/', i + 1, #parts))
            for _index_1 = 1, #_list_0 do
              local result = _list_0[_index_1]
              results[ri], ri = result, ri + 1
            end
          end
        end
        if (matchglob(file, prefix .. '**')) and isdir(file) then
          local _list_0 = wildcard(file .. '/**' .. suffix)
          for _index_1 = 1, #_list_0 do
            local result = _list_0[_index_1]
            results[ri], ri = result, ri + 1
          end
        end
      end
      return results
    end
    if match(part, '%*') then
      if not (exists(prevpath)) then
        return { }
      end
      local files = lswithpath(prevpath)
      if i == #parts then
        return matchglob(files, glob)
      end
      local results, ri = { }, 1
      for _index_0 = 1, #files do
        local file = files[_index_0]
        if (matchglob(file, currpath)) and isdir(file) then
          local _list_0 = wildcard(file .. '/' .. concat(parts, '/', i + 1, #parts))
          for _index_1 = 1, #_list_0 do
            local result = _list_0[_index_1]
            results[ri], ri = result, ri + 1
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
local parent
parent = function(file)
  return normalizepath(file .. '/..')
end
local actualmkdir = mkdir
mkdir = function(dir)
  actualmkdir(dir)
  return clearentry(parent(dir))
end
local mkdirs
mkdirs = function(dir)
  do
    local attr = attributes(normalizepath(dir))
    if attr then
      if attr.mode == 'directory' then
        return 
      end
      error("Can't mkdirs " .. tostring(dir) .. ": file exists")
    end
  end
  mkdirs(parent(dir))
  if not (pcall(function()
    return actualmkdir(dir)
  end)) then
    clearentry(parent(dir))
    clearentry(dir)
    if not (isdir(dir)) then
      error("Failed to mkdirs " .. tostring(dir) .. ": last mkdir failed")
    end
  end
  clearentry(parent(dir))
  return clearentry(dir)
end
do
  local _tbl_0 = { }
  for k, fn in pairs(fs) do
    _tbl_0[k] = withcache(fn)
  end
  fs = _tbl_0
end
fs.normalizepath = normalizepath
fs.ls = ls
fs.lswithpath = lswithpath
fs.matchglob = matchglob
fs.exists = exists
fs.isdir = isdir
fs.wildcard = wildcard
fs.parent = parent
fs.mkdir = mkdir
fs.mkdirs = mkdirs
fs.clearcache = clearcache
fs.clearentry = clearentry
fs.disableentry = disableentry
fs.disablecache = disablecache
fs.enablecache = enablecache
fs.backend = backend
return setmetatable(fs, {
  __call = function(self)
    return {
      'dir',
      'ls',
      'normalizepath',
      'exists',
      'isdir',
      'wildcard',
      'mkdir',
      'mkdirs'
    }
  end
})
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._fs.cmd" ] = function( ... ) local arg = _G.arg;
local escape
escape = require('moonbuild._cmd').escape
local execute
execute = require('moonbuild.compat.execute').execute
local popen
popen = io.popen
local gmatch, match, sub
do
  local _obj_0 = string
  gmatch, match, sub = _obj_0.gmatch, _obj_0.match, _obj_0.sub
end
if not ((execute("which ls >/dev/null 2>&1")) and (execute("which stat >/dev/null 2>&1"))) then
  error("commands ls and stat aren't available")
end
return {
  dir = function(path)
    local _accum_0 = { }
    local _len_0 = 1
    for file in (popen("ls -1 " .. tostring(escape(path)))):lines() do
      _accum_0[_len_0] = file
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end,
  attributes = function(path)
    local fd = popen("stat -c '%d %i %A %h %u %g %s %b %t %T %X %Y %Z' " .. tostring(escape(path)))
    local stat
    do
      local _accum_0 = { }
      local _len_0 = 1
      for part in gmatch((fd:read('*a')), "%S+") do
        _accum_0[_len_0] = part
        _len_0 = _len_0 + 1
      end
      stat = _accum_0
    end
    fd:close()
    fd = popen("stat -f -c '%S' " .. tostring(escape(path)))
    local blksize = match((fd:read('*a')), '%S+')
    fd:close()
    return {
      dev = tonumber(stat[1]),
      ino = tonumber(stat[2]),
      nlink = tonumber(stat[4]),
      uid = tonumber(stat[5]),
      gid = tonumber(stat[6]),
      size = tonumber(stat[7]),
      blocks = tonumber(stat[8]),
      blksize = tonumber(blksize),
      access = tonumber(stat[11]),
      modification = tonumber(stat[12]),
      change = tonumber(stat[13]),
      permissions = (function()
        return sub(stat[3], 2)
      end)(),
      mode = (function()
        local _exp_0 = sub(stat[3], 1, 1)
        if '-' == _exp_0 then
          return 'file'
        elseif 'd' == _exp_0 then
          return 'directory'
        elseif 'l' == _exp_0 then
          return 'link'
        elseif 's' == _exp_0 then
          return 'socket'
        elseif 'p' == _exp_0 then
          return 'named pipe'
        elseif 'c' == _exp_0 then
          return 'char device'
        elseif 'b' == _exp_0 then
          return 'block device'
        else
          return 'other'
        end
      end)(),
      rdev = (function()
        return (tonumber(stat[9])) * 256 + (tonumber(stat[10]))
      end)()
    }
  end,
  mkdir = function(path)
    if not (execute("mkdir " .. tostring(escape(path)))) then
      return error("Mkdir " .. tostring(path) .. " failed")
    end
  end
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._fs.lfs" ] = function( ... ) local arg = _G.arg;
local dir, attributes, mkdir
do
  local _obj_0 = require('lfs')
  dir, attributes, mkdir = _obj_0.dir, _obj_0.attributes, _obj_0.mkdir
end
return {
  dir = function(path)
    local _accum_0 = { }
    local _len_0 = 1
    for v in dir(path) do
      _accum_0[_len_0] = v
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end,
  attributes = attributes,
  mkdir = function(path)
    local ok, err = mkdir(path)
    if not (ok) then
      return error("Failed to mkdir " .. tostring(path) .. ": " .. tostring(err))
    end
  end
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._fs.posix" ] = function( ... ) local arg = _G.arg;
local dir
dir = require('posix.dirent').dir
local stat, mkdir, S_IFMT, S_IFBLK, S_IFCHR, S_IFDIR, S_IFIFO, S_IFLINK, S_IFREG, S_IFSOCK
do
  local _obj_0 = require('posix.sys.stat')
  stat, mkdir, S_IFMT, S_IFBLK, S_IFCHR, S_IFDIR, S_IFIFO, S_IFLINK, S_IFREG, S_IFSOCK = _obj_0.stat, _obj_0.mkdir, _obj_0.S_IFMT, _obj_0.S_IFBLK, _obj_0.S_IFCHR, _obj_0.S_IFDIR, _obj_0.S_IFIFO, _obj_0.S_IFLINK, _obj_0.S_IFREG, _obj_0.S_IFSOCK
end
local band, btest
do
  local _obj_0 = require('moonbuild.compat.bit')
  band, btest = _obj_0.band, _obj_0.btest
end
local concat
concat = table.concat
return {
  dir = dir,
  attributes = function(path)
    local st = stat(path)
    if not (st) then
      return nil
    end
    local mode = st.st_mode
    return {
      mode = (function()
        local ty = band(mode, S_IFMT)
        local _exp_0 = ty
        if S_IFREG == _exp_0 then
          return 'file'
        elseif S_IFDIR == _exp_0 then
          return 'directory'
        elseif S_IFLINK == _exp_0 then
          return 'link'
        elseif S_IFSOCK == _exp_0 then
          return 'socket'
        elseif S_IFIFO == _exp_0 then
          return 'named pipe'
        elseif S_IFCHR == _exp_0 then
          return 'char device'
        elseif S_IFBLK == _exp_0 then
          return 'block device'
        else
          return 'other'
        end
      end)(),
      permissions = (function()
        local _suid = btest(mode, 2048)
        local _sgid = btest(mode, 1024)
        local _stic = btest(mode, 512)
        local _ur = btest(mode, 256)
        local _uw = btest(mode, 128)
        local _ux = btest(mode, 64)
        local _gr = btest(mode, 32)
        local _gw = btest(mode, 16)
        local _gx = btest(mode, 8)
        local _or = btest(mode, 4)
        local _ow = btest(mode, 2)
        local _ox = btest(mode, 1)
        return concat({
          _ur and 'r' or '-',
          _uw and 'w' or '-',
          _suid and 's' or (_ux and 'x' or '-'),
          _gr and 'r' or '-',
          _gw and 'w' or '-',
          _sgid and 's' or (_gx and 'x' or '-'),
          _or and 'r' or '-',
          _ow and 'w' or '-',
          _stic and 't' or (_ox and 'x' or '-')
        })
      end)(),
      dev = st.st_dev,
      ino = st.st_ino,
      nlink = st.st_nlink,
      uid = st.st_uid,
      gid = st.st_gid,
      rdev = st.st_rdev,
      access = st.st_atime,
      modification = st.st_mtime,
      change = st.st_ctime,
      size = st.st_size,
      blocks = st.st_blocks,
      blksize = st.st_blksize
    }
  end,
  mkdir = function(path)
    local ok, err = mkdir(path)
    if not (ok) then
      return error("Failed to mkdir " .. tostring(path) .. ": " .. tostring(err))
    end
  end
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild._util" ] = function( ... ) local arg = _G.arg;
local to_lua
to_lua = require('moonscript.base').to_lua
local parseargs, cmdrst
do
  local _obj_0 = require('moonbuild._cmd')
  parseargs, cmdrst = _obj_0.parseargs, _obj_0.cmdrst
end
local gmatch, match, gsub
do
  local _obj_0 = string
  gmatch, match, gsub = _obj_0.gmatch, _obj_0.match, _obj_0.gsub
end
local open
open = io.open
local util = { }
local _pkgconfig
_pkgconfig = function(mode, ...)
  return parseargs(cmdrst('pkg-config', "--" .. tostring(mode), ...))
end
local pkgconfig = setmetatable({ }, {
  __index = function(self, mode)
    return function(...)
      return _pkgconfig(mode, ...)
    end
  end
})
local _cdeps
_cdeps = function(cc, cflags, path)
  local raw = cmdrst(cc, cflags, '-M', path)
  local rawlist = gsub((match(raw, ':(.+)')), '\\\n', ' ')
  local _accum_0 = { }
  local _len_0 = 1
  for v in gmatch(rawlist, '%S+') do
    _accum_0[_len_0] = v
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local cdeps = setmetatable({ }, {
  __index = function(self, cc)
    return function(path, cflags)
      return _cdeps(cc, cflags, path)
    end
  end,
  __call = function(self, path, cflags)
    return _cdeps('cc', cflags, path)
  end
})
local readfile
readfile = function(filename)
  local fd, err = open(filename, 'rb')
  if not (fd) then
    error(err)
  end
  local data
  data, err = fd:read('*a')
  if not (data) then
    error(err)
  end
  fd:close()
  return data
end
local writefile
writefile = function(filename, data)
  local fd, err = open(filename, 'wb')
  if not (fd) then
    error(err)
  end
  local ok
  ok, err = fd:write(data)
  if not (ok) then
    error(err)
  end
  fd:close()
  return nil
end
local moonc
moonc = function(infile, outfile)
  local code, err = to_lua(readfile(infile))
  if not (code) then
    error("Failed to compile " .. tostring(self.infile) .. ": " .. tostring(err))
  end
  return writefile(outfile, code)
end
util.pkgconfig = pkgconfig
util.cdeps = cdeps
util.readfile = readfile
util.writefile = writefile
util.moonc = moonc
return setmetatable(util, {
  __call = function(self)
    local _accum_0 = { }
    local _len_0 = 1
    for k in pairs(util) do
      _accum_0[_len_0] = k
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
})
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.compat.bit" ] = function( ... ) local arg = _G.arg;
local loadstring = loadstring or load
local floor, ceil, pow
do
  local _obj_0 = math
  floor, ceil, pow = _obj_0.floor, _obj_0.ceil, _obj_0.pow
end
local band = loadstring([[local a, b = ...; return a & b ]])
local bor = loadstring([[local a, b = ...; return a | b ]])
local bxor = loadstring([[local a, b = ...; return a ~ b ]])
local bnot = loadstring([[local a    = ...; return ~a    ]])
local shl = loadstring([[local a, b = ...; return a << b]])
local shr = loadstring([[local a, b = ...; return a >> b]])
if not (band) then
  local _checkint
  _checkint = function(n)
    if n % 1 == 0 then
      return n
    else
      return error("not an int")
    end
  end
  local _shl
  _shl = function(a, b)
    return a * pow(2, b)
  end
  local _shr
  _shr = function(a, b)
    local v = a / pow(2, b)
    if v < 0 then
      return ceil(v)
    else
      return floor(v)
    end
  end
  local _shr1
  _shr1 = function(n)
    n = n / 2
    if n < 0 then
      return ceil(v)
    else
      return floor(v)
    end
  end
  local _band
  _band = function(a, b)
    local v = 0
    local n = 1
    for i = 0, 63 do
      if a % 2 == 1 and b % 2 == 1 then
        v = v + n
      end
      if i ~= 63 then
        a = _shr1(a)
        b = _shr1(b)
        n = n * 2
      end
    end
    return v
  end
  local _bor
  _bor = function(a, b)
    local v = 0
    local n = 1
    for i = 0, 63 do
      if a % 2 == 1 or b % 2 == 1 then
        v = v + n
      end
      if i ~= 63 then
        a = _shr1(a)
        b = _shr1(b)
        n = n * 2
      end
    end
    return v
  end
  local _bxor
  _bxor = function(a, b)
    local v = 0
    local n = 1
    for i = 0, 63 do
      if a % 2 ~= b % 2 then
        v = v + n
      end
      if i ~= 63 then
        a = _shr1(a)
        b = _shr1(b)
        n = n * 2
      end
    end
    return v
  end
  local _bnot
  _bnot = function(a)
    local v = 0
    local n = 1
    for i = 0, 63 do
      if a % 2 == 0 then
        v = v + n
      end
      if i ~= 63 then
        a = _shr1(a)
        n = n * 2
      end
    end
    return v
  end
  band = function(a, b)
    return _band((_checkint(a)), (_checkint(b)))
  end
  bor = function(a, b)
    return _bor((_checkint(a)), (_checkint(b)))
  end
  bxor = function(a, b)
    return _bxor((_checkint(a)), (_checkint(b)))
  end
  bnot = function(a)
    return _bnot((_checkint(a)))
  end
  shl = function(a, b)
    return _shl((_checkint(a)), (_checkint(b)))
  end
  shr = function(a, b)
    return _shr((_checkint(a)), (_checkint(b)))
  end
end
local btest
btest = function(a, b)
  return (band(a, b)) == b
end
return {
  band = band,
  bor = bor,
  bxor = bxor,
  bnot = bnot,
  shl = shl,
  shr = shr,
  btest = btest
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.compat.ctx" ] = function( ... ) local arg = _G.arg;
local pcall = require('moonbuild.compat.pcall')
local runwithcontext
if setfenv then
  runwithcontext = function(fn, ctx, ...)
    local env = getfenv(fn)
    setfenv(fn, ctx)
    local data, ndata, ok
    local acc
    acc = function(succ, ...)
      ok = succ
      if succ then
        data = {
          ...
        }
        ndata = select('#', ...)
      else
        data = ...
      end
    end
    acc(pcall(fn, ...))
    setfenv(fn, env)
    if ok then
      return unpack(data, 1, ndata)
    else
      return error(data)
    end
  end
else
  local dump
  dump = string.dump
  runwithcontext = function(fn, ctx, ...)
    local code = dump(fn, false)
    fn = load(code, 'runwithcontext', 'b', ctx)
    return fn(...)
  end
end
return {
  runwithcontext = runwithcontext
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.compat.execute" ] = function( ... ) local arg = _G.arg;
local execute
execute = os.execute
return {
  execute = function(cmd)
    local a, b, c = execute(cmd)
    if (type(a)) == 'boolean' then
      return a, b, c
    else
      return a == 0 or nil, 'exit', a
    end
  end
}
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.compat.pcall" ] = function( ... ) local arg = _G.arg;
local pcall = _G.pcall
local unpack = _G.unpack or table.unpack
local testfn
testfn = function(a, b)
  return a == b and a == 1 and true or error()
end
local testok, testrst = pcall(testfn, 1, 1)
if not (testok and testrst) then
  local realpcall = pcall
  pcall = function(fn, ...)
    local args = {
      n = (select('#', ...)),
      ...
    }
    return realpcall(function()
      return fn(unpack(args, 1, args.n))
    end)
  end
end
return pcall
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.context" ] = function( ... ) local arg = _G.arg;
local runwithcontext
runwithcontext = require('moonbuild.compat.ctx').runwithcontext
local topenv = require('moonbuild.env.top')
local initenv = require('moonbuild.env.init')
local includes
includes = require('moonbuild._common').includes
local insert
insert = table.insert
local Context
do
  local _class_0
  local _base_0 = {
    addvar = function(self, var)
      self.variables[var.name] = var
    end,
    addinit = function(self, fn)
      return insert(self.inits, fn)
    end,
    addtarget = function(self, target)
      return insert(self.targets, target)
    end,
    resetexecuted = function(self)
      self.executedtargets = { }
    end,
    adddefault = function(self, target)
      if not (includes(self.targets, target)) then
        error("not a target of the current context: " .. tostring(target))
      end
      if not ((type(target.name)) == 'string') then
        error("not a named target")
      end
      return insert(self.defaulttargets, target.name)
    end,
    load = function(self, code, overrides)
      return runwithcontext(code, (topenv(self, overrides)))
    end,
    init = function(self)
      if self.inits[1] then
        local env = (initenv(self))
        local _list_0 = self.inits
        for _index_0 = 1, #_list_0 do
          local init = _list_0[_index_0]
          runwithcontext(code, env)
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.targets = { }
      self.defaulttargets = { }
      self.variables = { }
      self.inits = { }
    end,
    __base = _base_0,
    __name = "Context"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Context = _class_0
  return _class_0
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.core.DAG" ] = function( ... ) local arg = _G.arg;
local first, filter, foreach, flatten, patsubst, includes
do
  local _obj_0 = require('moonbuild._common')
  first, filter, foreach, flatten, patsubst, includes = _obj_0.first, _obj_0.filter, _obj_0.foreach, _obj_0.flatten, _obj_0.patsubst, _obj_0.includes
end
local runwithcontext
runwithcontext = require('moonbuild.compat.ctx').runwithcontext
local globalenv = require('moonbuild.env.global')
local exists, parent, mkdirs, clearentry, disableentry, attributes
do
  local _obj_0 = require('moonbuild._fs')
  exists, parent, mkdirs, clearentry, disableentry, attributes = _obj_0.exists, _obj_0.parent, _obj_0.mkdirs, _obj_0.clearentry, _obj_0.disableentry, _obj_0.attributes
end
local sort, insert, remove
do
  local _obj_0 = table
  sort, insert, remove = _obj_0.sort, _obj_0.insert, _obj_0.remove
end
local huge
huge = math.huge
local DepNode, FileTarget
local nodepriority
nodepriority = function(a, b)
  local ta = type(a.name)
  local tb = type(b.name)
  local da = #a.deps
  local db = #b.deps
  local sa = a.sync
  local sb = b.sync
  if ta == 'string' and tb ~= 'string' then
    return true
  elseif ta ~= 'string' and tb == 'string' then
    return false
  elseif a.priority > b.priority then
    return true
  elseif a.priority < b.priority then
    return false
  elseif sa and not sb then
    return false
  elseif sb and not sa then
    return true
  else
    return da < db
  end
end
local transclosure
transclosure = function(obj, prop)
  local elems = { }
  local i = 1
  local set = { }
  local imp
  imp = function(e)
    if not (e[prop]) then
      return 
    end
    local _list_0 = e[prop]
    for _index_0 = 1, #_list_0 do
      local v = _list_0[_index_0]
      if not set[v] then
        elems[i], i = v, i + 1
        set[v] = i
        imp(v)
      end
    end
  end
  imp(obj)
  return elems
end
local mtime
mtime = function(path)
  local attr = attributes(path)
  return attr and attr.modification
end
local DepGraph
do
  local _class_0
  local _base_0 = {
    addnode = function(self, name)
      if self.nodes[name] then
        return 
      end
      local elected = self:topresolvedeps(name)
      self.nodes[name] = elected
      local _list_0 = (transclosure(elected, 'deps'))
      for _index_0 = 1, #_list_0 do
        local dep = _list_0[_index_0]
        self.nodes[dep.name] = dep
        dep.deps = nil
      end
      elected.deps = nil
    end,
    topresolvedeps = function(self, name)
      local errors = { }
      local ok, rst = pcall(function()
        return self:resolvedeps(name, nil, errors)
      end)
      if ok then
        return rst
      else
        local msg = {
          "Failed to resolve target \'" .. tostring(name) .. "\'\n"
        }
        for _index_0 = 1, #errors do
          local e = errors[_index_0]
          if e.err:match('^moonbuild') then
            e.err = e.err:match(': (.+)$')
          end
        end
        for i = #errors, 1, -1 do
          local e = errors[i]
          insert(msg, tostring(string.rep('| ', e.level - 1)) .. "+-[" .. tostring(e.name) .. "] level " .. tostring(e.level) .. ": " .. tostring(e.err))
        end
        insert(msg, '')
        return error(table.concat(msg, '\n'))
      end
    end,
    resolvedeps = function(self, name, level, errors)
      if level == nil then
        level = 1
      end
      if errors == nil then
        errors = { }
      end
      do
        local node = self.nodes[name]
        if node then
          print("deps(" .. tostring(name) .. ") = " .. tostring(node.name or '[noname]'))
          return node, { }
        end
      end
      local candidates = filter({
        self.ctx.targets,
        FileTarget()
      }, function(target)
        return target:matches(name)
      end)
      local nodes = foreach(candidates, function(candidate)
        return {
          a = {
            pcall(function()
              return DepNode(self, candidate, name, level, errors)
            end)
          }
        }
      end)
      local resolved = foreach((filter(nodes, function(node)
        return node.a[1]
      end)), function(node)
        return node.a[2]
      end)
      sort(resolved, nodepriority)
      if not (resolved[1]) then
        local err = "Cannot resolve target " .. tostring(name) .. ": " .. tostring(#candidates) .. " candidates, " .. tostring(#resolved) .. " resolved"
        table.insert(errors, {
          name = name,
          level = level,
          err = err
        })
        error(err)
      end
      return resolved[1]
    end,
    buildablenodes = function(self)
      local _accum_0 = { }
      local _len_0 = 1
      for k, v in pairs(self.nodes) do
        if v:canbuild() and not v.built then
          _accum_0[_len_0] = v
          _len_0 = _len_0 + 1
        end
      end
      return _accum_0
    end,
    reset = function(self)
      for k, n in pairs(self.nodes) do
        n.built = false
      end
    end,
    resetchildren = function(self, names)
      local done = { }
      local stack
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #names do
          local v = names[_index_0]
          _accum_0[_len_0] = v
          _len_0 = _len_0 + 1
        end
        stack = _accum_0
      end
      while #stack ~= 0 do
        local _continue_0 = false
        repeat
          local name = remove(stack)
          if done[name] then
            _continue_0 = true
            break
          end
          done[name] = true
          local node = self.nodes[name]
          node.built = false
          local _list_0 = (node:children())
          for _index_0 = 1, #_list_0 do
            local n = _list_0[_index_0]
            insert(stack, n)
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, ctx, names)
      if names == nil then
        names = { }
      end
      self.ctx = ctx
      self.nodes = { }
      self.env = globalenv(self.ctx)
      for _index_0 = 1, #names do
        local name = names[_index_0]
        self:addnode(name)
      end
    end,
    __base = _base_0,
    __name = "DepGraph"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DepGraph = _class_0
end
do
  local _class_0
  local _base_0 = {
    children = function(self)
      local _accum_0 = { }
      local _len_0 = 1
      for k, n in pairs(self.dag.nodes) do
        if (includes(n.ins, self.name)) or (includes(n.after, self.name)) then
          _accum_0[_len_0] = k
          _len_0 = _len_0 + 1
        end
      end
      return _accum_0
    end,
    canbuild = function(self)
      local _list_0 = flatten({
        self.ins,
        self.after
      })
      for _index_0 = 1, #_list_0 do
        local node = _list_0[_index_0]
        if not self.dag.nodes[node].built then
          return false
        end
      end
      local _list_1 = self.ins
      for _index_0 = 1, #_list_1 do
        local file = _list_1[_index_0]
        if not exists(file) then
          error("Node " .. tostring(self.name) .. " has ran all of its parents, but can't run since " .. tostring(file) .. " doesn't exist. Did you mean to use after instead of depends?")
        end
      end
      return true
    end,
    build = function(self, opts)
      if opts == nil then
        opts = { }
      end
      local force = opts.force or false
      local quiet = opts.quiet or false
      if self.built or #self.buildfunctions == 0 then
        return false
      end
      if not (force or self:shouldbuild()) then
        return false
      end
      if not (quiet) then
        print(tostring(self.type == 'virtual' and "Running" or "Building") .. " " .. tostring(self.name) .. " [level " .. tostring(self.level) .. "]")
      end
      self:actuallybuild()
      return true
    end,
    shouldbuild = function(self)
      if #self.outs == 0 or #self.ins == 0 or self.type == 'virtual' then
        return true
      end
      local minout = huge
      local _list_0 = self.outs
      for _index_0 = 1, #_list_0 do
        local file = _list_0[_index_0]
        local time = mtime(file)
        if not time then
          return true
        end
        if time < minout then
          minout = time
        end
      end
      local maxin = 0
      local _list_1 = self.ins
      for _index_0 = 1, #_list_1 do
        local file = _list_1[_index_0]
        local time = mtime(file)
        if time > maxin then
          maxin = time
        end
      end
      return maxin > minout
    end,
    actuallybuild = function(self)
      if self.mkdirs then
        local _list_0 = self.outs
        for _index_0 = 1, #_list_0 do
          local file = _list_0[_index_0]
          mkdirs(parent(file))
        end
      end
      local _list_0 = self.outs
      for _index_0 = 1, #_list_0 do
        local file = _list_0[_index_0]
        disableentry(file)
      end
      local ctx = setmetatable({ }, {
        __index = function(_, k)
          local _exp_0 = k
          if 'infile' == _exp_0 or 'in' == _exp_0 then
            return self.ins[1]
          elseif 'infiles' == _exp_0 then
            return self.ins
          elseif 'outfile' == _exp_0 or 'out' == _exp_0 then
            return self.outs[1]
          elseif 'outfiles' == _exp_0 then
            return self.outs
          elseif 'name' == _exp_0 then
            return self.name
          else
            return error("No such field in TargetContext: " .. tostring(k))
          end
        end,
        __newindex = function(self, k)
          return error("Attempt to set field " .. tostring(k) .. " of TargetContext")
        end
      })
      local _list_1 = self.buildfunctions
      for _index_0 = 1, #_list_1 do
        local fn = _list_1[_index_0]
        runwithcontext(fn, self.dag.env, ctx)
      end
    end,
    updatecache = function(self)
      local _list_0 = self.outs
      for _index_0 = 1, #_list_0 do
        local file = _list_0[_index_0]
        clearentry(file)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, dag, target, name, level, errors)
      self.dag, self.name, self.level = dag, name, level
      self.priority = target.priority
      self.buildfunctions = target.buildfunctions
      self.mkdirs = target._mkdirs
      self.sync = target._sync
      self.type = target._type
      self.outs = foreach(target.outfiles, function(name)
        return patsubst(self.name, target.pattern, name)
      end)
      if #self.outs == 0 then
        self.type = 'virtual'
      end
      self.built = false
      local resolve
      resolve = function(name)
        return self.dag:resolvedeps((patsubst(self.name, target.pattern, name)), level + 1, errors)
      end
      local after = flatten(foreach(target.needtargets, resolve))
      local deps = flatten(foreach(target.infiles, resolve))
      if #target.depfunctions ~= 0 then
        local ctx = setmetatable({ }, {
          __index = function(_, k)
            local _exp_0 = k
            if 'infile' == _exp_0 or 'in' == _exp_0 then
              local f = first(deps)
              return f and f.name
            elseif 'infiles' == _exp_0 then
              return foreach(deps, function(self)
                return self.name
              end)
            elseif 'outfile' == _exp_0 or 'out' == _exp_0 then
              local f = first(self.outs)
              return f and f.name
            elseif 'outfiles' == _exp_0 then
              return foreach(self.outs, function(self)
                return self.name
              end)
            elseif 'name' == _exp_0 then
              return self.name
            else
              return error("No such field in TargetDepsContext: " .. tostring(k))
            end
          end,
          __newindex = function(self, k)
            return error("Attempt to set field " .. tostring(k) .. " of TargetDepsContext")
          end
        })
        local _list_0 = target.depfunctions
        for _index_0 = 1, #_list_0 do
          local depfn = _list_0[_index_0]
          deps = flatten(deps, foreach((runwithcontext(depfn, self.dag.env, ctx)), resolve))
        end
      end
      self.ins = foreach(deps, function(dep)
        return dep.name
      end)
      self.after = foreach(after, function(dep)
        return dep.name
      end)
      self.deps = flatten({
        deps,
        after
      })
      if #self.deps == 0 and #self.buildfunctions == 0 then
        self.built = true
      end
    end,
    __base = _base_0,
    __name = "DepNode"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DepNode = _class_0
end
do
  local _class_0
  local _base_0 = {
    matches = function(self, name)
      return exists(name)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.priority = -huge
      self.buildfunctions = { }
      self._mkdirs = false
      self._sync = false
      self._type = 'file'
      self.needtargets = { }
      self.infiles = { }
      self.depfunctions = { }
      self.outfiles = {
        '%'
      }
      self.pattern = '%'
    end,
    __base = _base_0,
    __name = "FileTarget"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  FileTarget = _class_0
end
return DepGraph
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.core.Pipeline" ] = function( ... ) local arg = _G.arg;
local Target = require('moonbuild.core.Target')
local _ = require('moonbuild._')
local flatten, patsubst
flatten, patsubst = _.flatten, _.patsubst
local Pipeline
do
  local _class_0
  local _base_0 = {
    sources = function(self, ...)
      self.lastsources = flatten(self.lastsources, ...)
    end,
    source = function(self, src)
      self.lastsources = flatten(self.lastsources, src)
    end,
    step = function(self, name, params)
      local public = true
      if (type(name)) == 'table' then
        public, params = false, name
      end
      local tgttype
      if params.pattern then
        if not ((type(params.pattern)) == 'table' and (type(params.pattern[1])) == 'string' and (type(params.pattern[2])) == 'string') then
          error("pattern must be a table with the same format as patsubst")
        end
        tgttype = 'pattern'
      elseif params.output or params.out then
        if not ((type(params.output or params.out)) == 'string') then
          error("output must be a string")
        end
        tgttype = 'single'
      else
        tgttype = error("invalid step type for pipeline: must be pattern or single (out/output)")
      end
      local tgtouts
      local _exp_0 = tgttype
      if 'pattern' == _exp_0 then
        tgtouts = patsubst(self.lastsources, params.pattern[1], params.pattern[2])
      elseif 'single' == _exp_0 then
        tgtouts = params.output or params.out
      end
      local tgtpatt
      local _exp_1 = tgttype
      if 'pattern' == _exp_1 then
        tgtpatt = params.pattern[2]
      elseif 'single' == _exp_1 then
        tgtpatt = nil
      end
      local tgtins
      local _exp_2 = tgttype
      if 'pattern' == _exp_2 then
        tgtins = params.pattern[1]
      elseif 'single' == _exp_2 then
        tgtins = self.lastsources
      end
      local tgtprod
      local _exp_3 = tgttype
      if 'pattern' == _exp_3 then
        tgtprod = params.pattern[2]
      elseif 'single' == _exp_3 then
        tgtprod = '%'
      end
      local tgt
      do
        local _with_0 = Target(self.ctx, tgtouts, {
          pattern = tgtpatt
        })
        _with_0:depends(tgtins)
        _with_0:produces(tgtprod)
        _with_0:fn(params.fn or error("pipeline steps need a fn"))
        tgt = _with_0
      end
      if params.mkdirs then
        tgt:mkdirs()
      end
      if params.sync then
        tgt:sync()
      end
      self.ctx:addtarget(tgt)
      if public then
        self.ctx:addtarget((function()
          do
            local _with_0 = Target(self.ctx, name)
            _with_0:depends(tgtouts)
            _with_0.public = true
            return _with_0
          end
        end)())
      end
      self.lastsources = tgtouts
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, ctx)
      self.ctx = ctx
      self.lastsources = { }
    end,
    __base = _base_0,
    __name = "Pipeline"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Pipeline = _class_0
  return _class_0
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.core.Target" ] = function( ... ) local arg = _G.arg;
local flatten, includes, patget
do
  local _obj_0 = require('moonbuild._common')
  flatten, includes, patget = _obj_0.flatten, _obj_0.includes, _obj_0.patget
end
local insert
insert = table.insert
local Target
do
  local _class_0
  local _base_0 = {
    matches = function(self, name)
      if self.name == name then
        return true
      end
      if (includes(self.name, name)) and patget(name, self.pattern) then
        return true
      end
      return false
    end,
    produces = function(self, ...)
      local n = #self.outfiles + 1
      local _list_0 = flatten(...)
      for _index_0 = 1, #_list_0 do
        local obj = _list_0[_index_0]
        self.outfiles[n], n = obj, n + 1
      end
    end,
    depends = function(self, ...)
      if (type(...)) == 'function' then
        return insert(self.depfunctions, (...))
      else
        local n = #self.infiles + 1
        local _list_0 = flatten(...)
        for _index_0 = 1, #_list_0 do
          local obj = _list_0[_index_0]
          self.infiles[n], n = obj, n + 1
        end
      end
    end,
    after = function(self, ...)
      local n = #self.needtargets + 1
      local _list_0 = flatten(...)
      for _index_0 = 1, #_list_0 do
        local tgt = _list_0[_index_0]
        self.needtargets[n], n = tgt, n + 1
      end
    end,
    fn = function(self, fn)
      return insert(self.buildfunctions, fn)
    end,
    sync = function(self)
      self._sync = true
    end,
    mkdirs = function(self)
      self._mkdirs = true
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, ctx, name, opts)
      if opts == nil then
        opts = { }
      end
      self.ctx, self.name = ctx, name
      if (type(self.name)) ~= 'string' then
        self.name = flatten(self.name)
      end
      self.pattern = opts.pattern or ((type(self.name)) == 'string' and self.name or '%')
      self.priority = opts.priority or 0
      if not ((type(self.pattern)) == 'string') then
        error("pattern must be a string")
      end
      if not ((type(self.priority)) == 'number' and self.priority % 1 == 0) then
        error("priority must be an int")
      end
      self.outfiles = { }
      self.infiles = { }
      self.needtargets = { }
      self.depfunctions = { }
      self.buildfunctions = { }
      self._mkdirs = false
      self._sync = false
      self._type = 'normal'
      self.public = false
    end,
    __base = _base_0,
    __name = "Target"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Target = _class_0
  return _class_0
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.core.Variable" ] = function( ... ) local arg = _G.arg;
local flatten
flatten = require('moonbuild._common').flatten
local Variable
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, name, ...)
      self.name = name
      self.public = false
      if (type(self.name)) == 'table' then
        if not ((type(next(self.name))) == 'string') then
          error("not a valid var table: " .. tostring(next(self.name)))
        end
        if next(self.name, (next(self.name))) then
          error("more than one var at once: " .. tostring(next(self.name)) .. ", " .. tostring(next(self.name, (next(self.name)))))
        end
        name = next(self.name)
        local param
        self.name, param = name, self.name
        local val = param[name]
        if (select('#', ...)) ~= 0 or (type(val)) == 'table' then
          self.value = flatten(val, ...)
        else
          self.value = val
        end
      elseif (select('#', ...)) ~= 1 or (type(...)) == 'table' then
        self.value = flatten(...)
      else
        self.value = ...
      end
    end,
    __base = _base_0,
    __name = "Variable"
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
  self.NIL = function() end
  Variable = _class_0
  return _class_0
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.core.executor" ] = function( ... ) local arg = _G.arg;
local ok, MultiProcessExecutor = pcall(function()
  return require('moonbuild.core.multiprocessexecutor')
end)
return ok and MultiProcessExecutor or require('moonbuild.core.singleprocessexecutor')
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.core.multiprocessexecutor" ] = function( ... ) local arg = _G.arg;
local SingleProcessExecutor = require('moonbuild.core.singleprocessexecutor')
local fork, _exit
do
  local _obj_0 = require('posix.unistd')
  fork, _exit = _obj_0.fork, _obj_0._exit
end
local wait
wait = require('posix.sys.wait').wait
local open, stderr
do
  local _obj_0 = io
  open, stderr = _obj_0.open, _obj_0.stderr
end
local match
match = string.match
local Executor
do
  local _class_0
  local _base_0 = {
    execute = function(self, opts)
      if self.nparallel == 1 then
        return (SingleProcessExecutor(self.dag, 1)):execute(opts)
      end
      local block = self.dag:buildablenodes()
      while #block ~= 0 do
        for _index_0 = 1, #block do
          local node = block[_index_0]
          self:addprocess(node, opts)
          if self.nprocesses == self.nparallel then
            self:waitprocess()
          end
        end
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self.dag:buildablenodes()
          for _index_0 = 1, #_list_0 do
            local node = _list_0[_index_0]
            if not self.building[node] then
              _accum_0[_len_0] = node
              _len_0 = _len_0 + 1
            end
          end
          block = _accum_0
        end
        while #block == 0 and self.nprocesses ~= 0 do
          self:waitprocess()
          do
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = self.dag:buildablenodes()
            for _index_0 = 1, #_list_0 do
              local node = _list_0[_index_0]
              if not self.building[node] then
                _accum_0[_len_0] = node
                _len_0 = _len_0 + 1
              end
            end
            block = _accum_0
          end
        end
      end
      while self.nprocesses ~= 0 do
        self:waitprocess()
      end
      for name, node in pairs(self.dag.nodes) do
        if not (node.built) then
          error("Node " .. tostring(name) .. " wasn't built")
        end
      end
      if not (opts.quiet) then
        if self.nbuilt == 0 then
          return print("Nothing to be done")
        else
          return print("Built " .. tostring(self.nbuilt) .. " targets")
        end
      end
    end,
    addprocess = function(self, node, opts)
      if node.sync then
        while self.nprocesses ~= 0 do
          self:waitprocess()
        end
        node:build(opts)
        node.built = true
        node:updatecache()
        return 
      end
      local pid = fork()
      if not (pid) then
        error("Failed to fork")
      end
      if pid ~= 0 then
        self.processes[pid] = node
        self.nprocesses = self.nprocesses + 1
        self.building[node] = true
      else
        local ok, status = pcall(function()
          return node:build(opts)
        end)
        if ok then
          _exit(status and 0 or 2)
          return _exit(0)
        else
          stderr:write(status)
          return _exit(1)
        end
      end
    end,
    waitprocess = function(self)
      local pid, ty, status = wait()
      if not (pid) then
        error("Failed to wait")
      end
      if ty ~= 'exited' or status ~= 0 and status ~= 2 then
        error("Failed to build " .. tostring(self.processes[pid].name))
      end
      self.processes[pid].built = true
      self.processes[pid]:updatecache()
      self.processes[pid] = nil
      self.nprocesses = self.nprocesses - 1
      if status == 0 then
        self.nbuilt = self.nbuilt + 1
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, dag, nparallel)
      self.dag, self.nparallel = dag, nparallel
      self.processes = { }
      self.nprocesses = 0
      self.building = { }
      self.nbuilt = 0
    end,
    __base = _base_0,
    __name = "Executor"
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
  self.getmaxparallel = function(self)
    local fd = open('/proc/cpuinfo', 'r')
    if not (fd) then
      return 1
    end
    local ncpu = 0
    for line in fd:lines() do
      if match(line, '^processor%s*:') then
        ncpu = ncpu + 1
      end
    end
    fd:close()
    return ncpu == 0 and 1 or ncpu
  end
  Executor = _class_0
  return _class_0
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.core.singleprocessexecutor" ] = function( ... ) local arg = _G.arg;
local Executor
do
  local _class_0
  local _base_0 = {
    execute = function(self, opts)
      local nbuilt = 0
      local block = self.dag:buildablenodes()
      while #block ~= 0 do
        for _index_0 = 1, #block do
          local node = block[_index_0]
          if node:build(opts) then
            nbuilt = nbuilt + 1
          end
          node:updatecache()
          node.built = true
        end
        block = self.dag:buildablenodes()
      end
      for name, node in pairs(self.dag.nodes) do
        if not (node.built) then
          error("Node " .. tostring(name) .. " wasn't built")
        end
      end
      if not (opts.quiet) then
        if nbuilt == 0 then
          return print("Nothing to be done")
        else
          return print("Built " .. tostring(nbuilt) .. " targets")
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, dag, nparallel)
      self.dag, self.nparallel = dag, nparallel
    end,
    __base = _base_0,
    __name = "Executor"
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
  self.getmaxparallel = function(self)
    return 1
  end
  Executor = _class_0
  return _class_0
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.env.global" ] = function( ... ) local arg = _G.arg;
local _ = require('moonbuild._')
return function(ctx)
  local varlayer = setmetatable({ }, {
    __index = _G
  })
  for name, var in pairs(ctx.variables) do
    rawset(varlayer, name, var.value)
  end
  local env = setmetatable({ }, {
    __index = varlayer,
    __newindex = function(self, k)
      return error("attempt to assign to global variable '" .. tostring(k) .. "', which is disabled in the global env")
    end
  })
  rawset(env, '_', _)
  rawset(env, '_G', env)
  rawset(env, '_ENV', env)
  return env, varlayer
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.env.init" ] = function( ... ) local arg = _G.arg;
local Target = require('moonbuild.core.Target')
local Variable = require('moonbuild.core.Variable')
local Pipeline = require('moonbuild.core.Pipeline')
local _ = require('moonbuild._')
local flatten
flatten = _.flatten
return function(ctx)
  local varlayer = setmetatable({ }, {
    __index = _G
  })
  for name, var in pairs(ctx.variables) do
    rawset(varlayer, name, var.value)
  end
  local env = setmetatable({ }, {
    __index = varlayer,
    __newindex = function(self, k)
      return error("attempt to assign to global variable '" .. tostring(k) .. "', use the function 'var' instead")
    end
  })
  rawset(env, '_', _)
  rawset(env, '_G', env)
  rawset(env, '_ENV', env)
  rawset(env, 'var', function(...)
    local var = Variable(...)
    ctx:addvar(var)
    rawset(varlayer, var.name, var.value)
    return var
  end)
  rawset(env, 'target', function(name, opts)
    local target = Target(ctx, name, opts)
    ctx:addtarget(target)
    return target
  end)
  rawset(env, 'pipeline', function()
    return Pipeline(ctx)
  end)
  return env, varlayer
end
end
end

do
local _ENV = _ENV
package.preload[ "moonbuild.env.top" ] = function( ... ) local arg = _G.arg;
local initenv = require('moonbuild.env.init')
local Target = require('moonbuild.core.Target')
local Variable = require('moonbuild.core.Variable')
return function(ctx, overrides)
  local env, varlayer = initenv(ctx)
  rawset(env, 'default', function(target)
    ctx:adddefault(target)
    return target
  end)
  rawset(env, 'public', function(e)
    local clazz = ((getmetatable(e)) or { }).__class
    if clazz == Target then
      e.public = true
    elseif clazz == Variable then
      e.public = true
      local override = overrides[e.name]
      if override then
        if override == Variable.NIL then
          override = nil
        end
        e.value = override
        rawset(varlayer, e.name, override)
      end
    else
      error("cannot set an object of type " .. tostring(clazz and clazz.__name or type(e)) .. " public")
    end
    return e
  end)
  rawset(env, 'init', function(fn)
    if not ((type(fn)) == 'function') then
      error("you can only add functions to init")
    end
    return ctx:addinit(fn)
  end)
  return env, varlayer
end
end
end

local loadfile
loadfile = require('moonscript.base').loadfile
local Context = require('moonbuild.context')
local DepGraph = require('moonbuild.core.DAG')
local Executor = require('moonbuild.core.executor')
local _ = require('moonbuild._')
local insert
insert = table.insert
local moonbuild
moonbuild = function(...)
  local opts = { }
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    if (type(arg)) == 'string' then
      insert(opts, arg)
    elseif (type(arg)) == 'table' then
      for k, v in pairs(arg) do
        if (type(k)) ~= 'number' then
          opts[k] = v
        end
      end
      for i, v in ipairs(arg) do
        insert(opts, v)
      end
    else
      error("Invalid argument type " .. tostring(type(arg)) .. " for moonbuild")
    end
  end
  local buildfile = opts.buildfile or opts.b or 'Build.moon'
  opts.buildfile = buildfile
  local parallel = opts.parallel or opts.j or 1
  if parallel == 'y' then
    parallel = true
  end
  opts.parallel = parallel
  local quiet = opts.quiet or opts.q or false
  opts.quiet = quiet
  local force = opts.force or opts.f or false
  opts.force = force
  local verbose = opts.verbose or opts.v or false
  opts.verbose = verbose
  local ctx = Context()
  ctx:load((loadfile(buildfile)), opts)
  if verbose then
    print("Loaded buildfile")
  end
  ctx:init()
  if verbose then
    print("Initialized buildfile")
  end
  local targets = #opts == 0 and ctx.defaulttargets or opts
  local dag = DepGraph(ctx, targets)
  if verbose then
    print("Created dependancy graph")
  end
  local nparallel = parallel == true and Executor:getmaxparallel() or parallel
  if verbose then
    print("Building with " .. tostring(nparallel) .. " max parallel process" .. tostring(nparallel > 1 and "es" or ""))
  end
  local executor = Executor(dag, nparallel)
  executor:execute(opts)
  if verbose then
    return print("Finished")
  end
end
local table = {
  moonbuild = moonbuild,
  _ = _,
  Context = Context,
  DepGraph = DepGraph,
  Executor = Executor
}
return setmetatable(table, {
  __call = function(self, ...)
    return moonbuild(...)
  end,
  __index = function(self, name)
    return require("moonbuild." .. tostring(name))
  end
})