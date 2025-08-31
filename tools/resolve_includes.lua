-- ---------- resource-path helpers ----------
local RESOURCE_PATHS = {"."}

local function is_windows() return package.config:sub(1,1) == "\\" end
local function split(s, sep) local t = {}; for part in s:gmatch("([^"..sep.."]+)") do t[#t+1]=part end; return t end
local function expanduser(p)
  if p:sub(1,1) == "~" then
    local home = os.getenv(is_windows() and "USERPROFILE" or "HOME") or ""
    if p == "~" then return home end
    if p:sub(1,2) == "~/" or (is_windows() and p:sub(1,2) == "~\\") then return home .. p:sub(2) end
  end
  return p
end
local function path_join(a,b)
  if a=="" or a=="." then return b end
  local sep = is_windows() and "\\" or "/"
  if a:sub(-1)==sep then return a..b else return a..sep..b end
end
local function dirname(p)
  local sep = is_windows() and "\\" or "/"
  local i = p:match("^.*()"..sep); return i and p:sub(1,i-1) or "."
end
local function is_abs(p) return is_windows() and (p:match("^%a:[/\\]") or p:match("^\\\\")) or p:sub(1,1)=="/" end
local function file_exists(p) local f=io.open(p,"r"); if f then f:close(); return true end; return false end
local function find_file(name, current_dir)
  if is_abs(name) then return file_exists(name) and name or nil end
  if current_dir and current_dir~="" then
    local p = path_join(current_dir, name); if file_exists(p) then return p end
  end
  for _,base in ipairs(RESOURCE_PATHS) do
    local p = path_join(base, name); if file_exists(p) then return p end
  end
  return nil
end

-- ---------- content helpers ----------
local function strip_metadata(content)
  local out, in_meta = {}, false
  for line in content:gmatch("([^\n]*)\n?") do
    if line:match("^%-%-%-$") and not in_meta then
      in_meta = true
    elseif in_meta and line:match("^%-%-%-$") then
      in_meta = false
    elseif not in_meta then
      out[#out+1] = line
    end
  end
  return table.concat(out, "\n")
end

-- match include lines (robust to spaces; supports both syntaxes)
local function match_include_line(line)
  -- MkDocs-style: {% include-markdown "path.md" %}
  local m1 = line:match("^%s*{%%%s*include%-markdown%s+['\"]([^'\"]+)['\"][^%%]*%%}%s*$")
  if m1 then return m1 end
  -- Legacy: @include: path or @include "path"
  local m2 = line:match('^%s*@include:?%s*["“”]?[^A-Za-z0-9._/\\-]*([%w%._/\\%-]+)[^A-Za-z0-9._/\\-]*["“”]?%s*$')
  return m2
end

-- Resolve includes over a *whole markdown string*.
local function resolve_includes_text(content, depth, current_dir)
  depth = depth or 0
  local indent = string.rep("  ", depth)
  local out_lines = {}

  for line in content:gmatch("([^\n]*)\n?") do
    local target = match_include_line(line)
    if target then
      local found = find_file(target, current_dir)
      if found then
        print(indent .. "Include: " .. target .. " -> " .. found)
        local f = io.open(found, "r")
        if f then
          local included = f:read("*a"); f:close()
          local stripped = strip_metadata(included)
          local next_dir = dirname(found)
          local resolved = resolve_includes_text(stripped, depth+1, next_dir)
          out_lines[#out_lines+1] = resolved
        else
          print(indent .. "Error reading: " .. found)
          out_lines[#out_lines+1] = "% Failed to read include: " .. target
        end
      else
        print(indent .. "Missing include: " .. target)
        out_lines[#out_lines+1] = "% Missing include: " .. target
      end
    else
      out_lines[#out_lines+1] = line
    end
  end

  return table.concat(out_lines, "\n")
end

-- ---------- entry point ----------
function Pandoc(doc)
  print("Starting document assembly...")

  -- Build resource path list from meta/env
  RESOURCE_PATHS = {}
  local function add_path(p)
    p = pandoc.utils.stringify(p)
    if p and p ~= "" then table.insert(RESOURCE_PATHS, expanduser(p)) end
  end

  local meta_rp = doc.meta["resource-path"] or doc.meta["resourcepath"]
  if meta_rp then
    if type(meta_rp) == "table" and meta_rp.t == "MetaList" then
      for _, v in ipairs(meta_rp) do add_path(v) end
    else
      local list_sep = is_windows() and ";" or ":"
      local s = pandoc.utils.stringify(meta_rp)
      if s:find(list_sep, 1, true) then
        for _, p in ipairs(split(s, list_sep)) do add_path(p) end
      else
        for part in s:gmatch("[^,%s]+") do add_path(part) end
      end
    end
  end

  local env_rp = os.getenv("PANDOC_RESOURCE_PATH")
  if env_rp and env_rp ~= "" then
    local list_sep = is_windows() and ";" or ":"
    for _, p in ipairs(split(env_rp, list_sep)) do add_path(p) end
  end

  table.insert(RESOURCE_PATHS, ".")
  -- de-dup while preserving order
  local seen, norm = {}, {}
  for _, p in ipairs(RESOURCE_PATHS) do if not seen[p] then seen[p]=true; norm[#norm+1]=p end end
  RESOURCE_PATHS = norm

  print("Resource path search order:")
  for i, p in ipairs(RESOURCE_PATHS) do print(string.format("  [%d] %s", i, p)) end

  -- choose a base dir for top-level includes
  local root_dir = "."
  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    root_dir = dirname(PANDOC_STATE.input_files[1])
  end

  -- stringify whole doc, expand includes in plain text, then re-parse
  local full = pandoc.write(doc, "markdown")
  local resolved_markdown = resolve_includes_text(full, 0, root_dir)
  local parsed = pandoc.read(resolved_markdown, "markdown")

  print("Finished document assembly.")
  return pandoc.Pandoc(parsed.blocks, doc.meta)
end
