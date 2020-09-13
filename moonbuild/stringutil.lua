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
