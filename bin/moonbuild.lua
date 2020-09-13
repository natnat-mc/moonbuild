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
    return rewrite_traceback(trunc, err)
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
      local ok, err = pcall(function()
        return self.fn({
          ins = ins,
          outs = outs,
          infile = ins[1],
          outfile = outs[1],
          name = name
        })
      end)
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
local targets = { }
local defaulttarget = 'all'
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
  end
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
local ok, err = pcall(buildfn)
if not (ok) then
  if err then
    io.stderr:write(err, '\n')
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
      io.write("\t\t" .. tostring(name) .. " (" .. tostring(dep.name) .. ")\n")
    end
  end
  os.exit(0)
end
if #args.targets == 0 then
  BuildObject:build(defaulttarget)
end
local _list_0 = args.targets
for _index_0 = 1, #_list_0 do
  local target = _list_0[_index_0]
  BuildObject:build(target)
end
