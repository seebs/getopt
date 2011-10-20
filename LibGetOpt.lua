--[[ GetOpt
     Unix-style getopt

     GetOpt takes either a single string or a table of arguments, and returns
     a table of flags, arguments, and any non-flag/argument parameters as
     both a string and a table.

     For instance, given a table of arguments { "-a", "-b", "foo", "bar" },
     GetOpt.getopt("ab:", <table>) yields
     { "a" -> true,
       "b" -> "foo",
       "args" -> "bar",
       "argtable" -> [ "bar" ]
     }

     Table format:
     {
       { "long", "l", nil, "descr" } -- no argument, just a flag
       { "argument", "a", ":", "descr" } -- string argument
       { "number", "n", "#", "descr" } -- numeric argument
     }

     In the event of an error, getopt diagnoses as much as it can, and
     returns nil.
]]--

if not Library then Library = {} end
local GetOpt = {}
if not Library.LibGetOpt then Library.LibGetOpt = GetOpt end

GetOpt.sampletable = {
  { "number", "n", "#", "a sample numeric value" },
  { "boolean", "b", nil, "a simple flag" },
  { "text", "t", ":", "a text string" },
}

GetOpt.DebugLevel = 0
GetOpt.Version = "VERSION"

function GetOpt.Debug(level, text, arg1, arg2, arg3, arg4, arg5, arg6, arg7,
arg8, arg9)
  if (level <= GetOpt.DebugLevel) then
    print("GetOpt: " .. string.format(text or 'nil', arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9))
  end
end

function GetOpt.parseopt(options)
  local lookup = {}
  for w in string.gmatch(options, '%a%p?') do
    _, _, letter, flag = string.find(w, '(%a)(%p?)')
    if (flag == "") then
      flag = nil
    end
    local entry = { nil, letter, flag, "(no documentation available)" }
    table.insert(lookup, entry)
    GetOpt.Debug(3, "character %s, flag %s.", letter, flag or "nil")
  end
  GetOpt.Debug(2, "found %d flags in '%s'.", table.getn(lookup), options)
  return lookup
end

function GetOpt.find(options, option)
  if (option == nil or options == nil) then
    return nil
  end
  if (string.len(option) > 1) then
    for i, o in ipairs(options) do
      if (o[1] == option) then
	return o
      end
    end
  else
    for i, o in ipairs(options) do
      if (o[2] == option) then
	return o
      end
    end
  end
end

function GetOpt.long(options, option)
  local o = GetOpt.find(options, option)
  if (o) then
    return o[1]
  else
    return nil
  end
end

function GetOpt.short(options, option)
  local o = GetOpt.find(options, option)
  if (o) then
    return o[2]
  else
    return nil
  end
end

function GetOpt.descr(options, option)
  local o = GetOpt.find(options, option)
  if (o) then
    return o[4]
  else
    return nil
  end
end

function GetOpt.flag(options, option)
  local o = GetOpt.find(options, option)
  if (o) then
    GetOpt.Debug(3, "option '%s', flag '%s'", option, o[3] or 'nil')
    return o[3]
  else
    GetOpt.Debug(3, "option '%s' unfound!")
    return nil
  end
end

function GetOpt.print(options)
  GetOpt.Debug(0, "Known options: ")
  for i, o in ipairs(options) do
    local o_l = o[1]
    local o_s = o[2]
    local o_f = o[3]
    local o_d = o[4] or "(no description available)"
    local descr
    if (o_l and o_s) then
      descr = string.format("-%s (--%s): %s", o_s, o_l, o_d)
    elseif (o_l) then
      descr = string.format("--%s: %s", o_l, o_d)
    elseif (o_s) then
      descr = string.format("-%s: %s", o_s, o_d)
    else
      descr = string.format("inexplicably unreachable option: %s", o_d)
    end
    if (o_f) then
      if (o_f == ":") then
	descr = descr .. " (string)"
      elseif (o_f == "#") then
	descr = descr .. " (number)"
      else
	descr = descr .. " (... unknown format?)"
      end
    end
    GetOpt.Debug(0, "%s", descr)
  end
end

function GetOpt.dequote(args)
  local newargs = {}
  if (not args) then
    return newargs
  end
  if (type(args) ~= 'string') then
    GetOpt.Debug(0, "Was asked to dequote a non-string, can't do that.")
    return newargs
  end
  local current = ''
  local word = false
  -- the "do repeat ... until true end" turns a break into a continue;
  -- that's fine by me
  local done = false
  local backslash = false
  local quoted = false
  for index=1,string.len(args) do
    repeat
      local ch = args:sub(index, index)
      if not ch then
	GetOpt.Debug(4, "got nil trying to read char %d of <%s>", index, args)
        break
      else
        GetOpt.Debug(4, "index %d of <%s>, got <%s>, current <%s>", index, args, ch or 'nil', current or 'nil')
      end
      -- if we are not in a word, skip spaces
      if not word then
	if (backslash) then
	  -- no matter what the next character is, it is the start
	  -- of a word and has no other meaning
	  word = true
	  current = ch
	  backslash = false
	else
	  if (ch == '\\') then
	    backslash = true
	    break
	  elseif (ch == '"') then
	    quoted = true
	    -- quoting starts a word even if there's nothing else in it
	    word = true
	    break
	  elseif (not quoted and string.find(ch, '%s')) then
	    -- this is a space, it's not quoted, we already checked
	    -- for backslash, we're not in a word... skip it
	    break
	  else
	    -- anything else just starts a word
	    word = true
	    current = ch
	  end
        end
      else
        if (backslash) then
	  current = current .. ch
	  backslash = false
	else
	  if (ch == '\\') then
	    backslash = true
	    break
	  elseif (ch == '"') then
	    quoted = not quoted
	  elseif (not quoted and string.find(ch, '%s')) then
	    table.insert(newargs, current)
	    current = ''
	    word = false
	  else
	    current = current .. ch
	  end
	end
      end
    until true
    if done then
      break
    end
  end
  if (quoted or backslash) then
    GetOpt.Debug(0, "Unterminated quote or backslash.")
    newargs = {}
  elseif (word) then
    table.insert(newargs, current)
  end
  return newargs
end

function GetOpt.getopt(options, args)
  local output = {}; 
  if (args == nil) then
    return output
  end
  if (type(options) ~= 'table') then
    options = GetOpt.parseopt(options)
  end
  if (type(args) ~= 'table') then
    args = GetOpt.dequote(args)
    GetOpt.Debug(2, "converted string to %d arguments.", table.getn(args))
  end
  local expected = {}
  local extra = {}
  local extra_text = ""
  local done = false
  for i, arg in ipairs(args) do
    GetOpt.Debug(2, "%d: '%s'", i, arg)
    local long = string.match(arg, "^%-%-(.*)$")
    local short = string.match(arg, "^%-(.*)$")
    if (done) then
      table.insert(extra, arg)
      if (string.len(extra_text)) then
        extra_text = extra_text .. " " .. arg
      else
	extra_text = arg
      end
    elseif (table.getn(expected) > 0) then
      local slot = table.remove(expected, 1)
      if (GetOpt.flag(options, slot) == "#") then
	if (tonumber(arg) == nil) then
	  GetOpt.Debug(0, "Option '%s' requires numeric value, which '%s' is not.", slot, arg)
	  return nil
	else
	  output[slot] = tonumber(arg)
	end
      else
        output[slot] = arg
      end
    elseif (long) then
      GetOpt.Debug(2, "long option: %s", long)
      if (long == "") then
	GetOpt.Debug(2, "found forced end of options.")
	done = true
      else
	if (GetOpt.find(long)) then
	  if (GetOpt.flag(options, long)) then
	    table.insert(expected, long)
	  else
	    output[long] = true
	  end
        else
	  GetOpt.Debug(0, "unknown long option '--%s'.", long)
	  return nil
	end
      end
    elseif (short) then
      GetOpt.Debug(2, "short options: '%s'", short)
      for c in string.gmatch(short, '.') do
	if (c == '?') then
	  GetOpt.print(options)
	  return nil
	elseif (not string.find(c, '%w')) then
	  GetOpt.Debug(0, "Only alphanumeric values are accepted as flags (%s).", c)
	  return nil
	end
	if (GetOpt.find(options, c)) then
	  if (GetOpt.flag(options, c)) then
	    table.insert(expected, c)
	  else
	    output[c] = true
	  end
	else
	  GetOpt.Debug(0, "Unknown flag '-%s'.", c)
	  return nil
	end
      end
    else
      GetOpt.Debug(2, "Not an option -- ending options")
      table.insert(extra, arg)
      extra_text = arg
      done = true
    end
  end
  if (table.getn(expected) > 0) then
    GetOpt.Debug(0, "Option '%s' expected an argument, which was missing.",
	expected[1])
    return nil
  end
  output["leftover"] = extra_text
  output["leftover_args"] = extra
  local mirrors = {}
  for k, v in pairs(output) do
    if (type(v) == "string") then
      GetOpt.Debug(2, "%s -> \"%s\"", k, v)
    elseif (type(v) == "table") then
      GetOpt.Debug(2, "%s -> table [%d items]", k, table.getn(v))
    elseif (type(v) == "number") then
      GetOpt.Debug(2, "%s -> %d", k, v)
    elseif (type(v) == "boolean" and v == true) then
      GetOpt.Debug(2, "%s is set", k)
    else
      GetOpt.Debug(2, "%s -> [%s]", k, type(v))
    end
    if (string.len(k) == 1) then
      local l = GetOpt.long(options, k)
      if (l) then
	mirrors[l] = v
      end
    else
      local s = GetOpt.short(options, k)
      if (s) then
	mirrors[s] = v
      end
    end
  end
  for k, v in pairs(mirrors) do
    output[k] = v
  end
  return output
end

function GetOpt.slashcommand(args)
  x = GetOpt.getopt("d#", args)
  -- This is for debugging with the lovely TableShow
  GetOpt.recent = x
  GetOpt.Debug(0, "version %s", GetOpt.Version)
  if (x) then
    if (x.d) then
      GetOpt.Debug(0, "Setting debug level to %d", x.d)
      GetOpt.DebugLevel = x.d
    end
    if (x.leftover_args) then
      for i, o in ipairs(x.leftover_args) do
        GetOpt.Debug(0, "%d: <%s>", i, o)
      end
    end
  end
end

local slashgetopt = Command.Slash.Register("getopt")
if (slashgetopt) then
  table.insert(slashgetopt, { GetOpt.slashcommand, "LibGetOpt", "/getopt" })
end

function GetOpt.makeslash(opts, addonname, name, func)
  local newcommand = Command.Slash.Register(name)
  local dummy = function(args)
    func(GetOpt.getopt(opts, args))
  end
  if (newcommand) then
    table.insert(newcommand, { dummy, addonname, string.format("/%s", name) })
  end
end
