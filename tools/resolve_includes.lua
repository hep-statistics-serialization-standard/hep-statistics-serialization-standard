-- tools/resolve_includes.lua
-- Expand MkDocs-style {% include-markdown "..." %} and @include ...,
-- replacing ONLY the matching block with parsed Blocks. If no matches
-- are seen in the AST pass, fall back to raw-text pre-read expansion.

---------------- Path helpers ----------------
local RESOURCE_PATHS, ROOT_DIR = nil, "."
local META_RESOURCE_PATH, INITIALIZED = nil, false
local EXPANSIONS = 0   -- count successful replacements
local VERBOSE = (os.getenv("INCLUDE_DEBUG") == "1")

local function log(...) if VERBOSE then print(...) end end
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
local function is_abs(p)
  if is_windows() then return p:match("^%a:[/\\]") or p:match("^\\\\") end
  return p:sub(1,1)=="/"
end
local function file_exists(p) local f=io.open(p,"rb"); if f then f:close(); return true end; return false end
local function find_file(name, current_dir)
  if is_abs(name) then return file_exists(name) and name or nil end
  if current_dir and current_dir~="" then
    local p = path_join(current_dir, name); if file_exists(p) then return p end
  end
  for _,base in ipairs(RESOURCE_PATHS or { "." }) do
    local p = path_join(base, name); if file_exists(p) then return p end
  end
  return nil
end


-- MkDocs fence info -> Pandoc curly-brace attributes
-- Turns:  ```json title="X" linenums="1"
-- into:   ```{.json title="X" linenums="1"}
-- Logs every rewrite. Works for ``` and ~~~, >=3 chars.
local function mkdocs_fences_to_pandoc(md)
  local out = {}
  local in_fence = false
  local fence_char, fence_len = nil, 0

  local function trim(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end
  local function all_same_char(s)
    local ch = s:sub(1,1)
    return not s:find("[^"..ch.."]")
  end

  for line in md:gmatch("([^\n]*)\n?") do
    if not in_fence then
      -- opener: indent + run of backticks/ tildes + optional info
      local lead, fence, rest = line:match("^([ \t]*)([`~]+)%s*(.*)$")
      if fence and #fence >= 3 and all_same_char(fence) then
        fence_char, fence_len = fence:sub(1,1), #fence
        local info = trim(rest or "")
        if info ~= "" and not info:match("^%s*%{") then
          -- split "lang attrs…" (if first token has '=', treat as attrs-only)
          local first = info:match("^([^%s]+)") or ""
          local is_kv = first:find("=") ~= nil
          local lang, attrs
          if is_kv then lang, attrs = nil, info else lang, attrs = first, trim(info:sub(#first+1)) end

          local inside = ""
          if lang and lang ~= "" then inside = (lang:sub(1,1) ~= ".") and ("."..lang) or lang end
          if attrs and attrs ~= "" then inside = (inside ~= "" and (inside.." "..attrs) or attrs) end

          if inside ~= "" then
            local new_line = string.format("%s%s{%s}", lead, fence, inside) -- no space before {
            print("fence-rewrite:", line)
            print("           ->", new_line)
            table.insert(out, new_line)
            in_fence = true
          else
            table.insert(out, line); in_fence = true
          end
        else
          table.insert(out, line); in_fence = true
        end
      else
        table.insert(out, line)
      end
    else
      -- closer: same char, at least same length, nothing else on line (except ws)
      local closer = line:match("^%s*("..fence_char.."+)%s*$")
      if closer and #closer >= fence_len then
        in_fence, fence_char, fence_len = false, nil, 0
      end
      table.insert(out, line)
    end
  end

  return table.concat(out, "\n")
end


---------------- Content helpers ----------------
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

-- Build literal text from inlines, preserving raw tokens.
local function inlines_text(inls)
  local parts = {}
  for _,x in ipairs(inls) do
    if x.t == "Str" then parts[#parts+1] = x.text
    elseif x.t == "Space" or x.t == "SoftBreak" then parts[#parts+1] = " "
    elseif x.t == "LineBreak" then parts[#parts+1] = "\n"
    elseif x.t == "RawInline" or x.t == "Code" then parts[#parts+1] = x.text
    else parts[#parts+1] = pandoc.utils.stringify(x) end
  end
  return table.concat(parts)
end

-- Accept if directive is alone on its line/block.
local function match_include_line(text)
  text = text:gsub("^%s+",""):gsub("%s+$","")

  -- MkDocs-style: {% include-markdown "path" %}
  -- (allow arbitrary spacing and trailing options)
  local _, path = text:match('^{%s*%%%s*include%-markdown%s*([\'"])(.-)%1.-%%%s*}%s*$')
  if path then return path end

  -- Legacy: @include: "path" or @include "path"
  local _, p2 = text:match('^@include:?%s*([\'"])(.-)%1%s*$')
  if p2 then return p2 end

  -- Legacy bare: @include: chapters/file.md
  local bare = text:match('^@include:?%s*([%w%._/%-%\\ ][%w%._/%-%\\ ]*)$')
  if bare then return bare:gsub("%s+$","") end

  return nil
end

-- Recursively expand include directives in a raw markdown string.
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
        local f = io.open(found, "rb")
        if f then
          local included = f:read("*a"); f:close()
          local stripped  = strip_metadata(included)
          local next_dir  = dirname(found)
          local resolved  = resolve_includes_text(stripped, depth+1, next_dir)
          if #out_lines > 0 and out_lines[#out_lines] ~= "" then out_lines[#out_lines+1] = "" end
          out_lines[#out_lines+1] = resolved
          if resolved ~= "" and resolved:sub(-1) ~= "\n" then out_lines[#out_lines+1] = "" end
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

-- Parse markdown using the same reader + options as the main invocation.
local function parse_markdown(md)
  -- Format string exactly as passed on CLI (e.g. "markdown+...").
  local reader_fmt = (PANDOC_STATE and PANDOC_STATE.input_format) or "markdown"
  -- Reader options from Pandoc (Pandoc ≥ 3 exposes PANDOC_READER_OPTIONS).
  local reader_opts = rawget(_G, "PANDOC_READER_OPTIONS") or pandoc.ReaderOptions()
  return pandoc.read(md, reader_fmt, reader_opts)
end


-- Convert an include path into Blocks (resolving nested includes).
local function blocks_from_include(target, base_dir)
  local found = find_file(target, base_dir)
  if not found then
    return { pandoc.Para{ pandoc.Str("% Missing include: " .. target) } }
  end
  local f = io.open(found, "rb")
  if not f then
    return { pandoc.Para{ pandoc.Str("% Failed to read include: " .. target) } }
  end
  local raw = f:read("*a"); f:close()
  local text_no_meta = strip_metadata(raw)
  local fully_resolved_text = resolve_includes_text(text_no_meta, 1, dirname(found))
  -- convert MkDocs fence titles to Pandoc attributes for Pandoc parsing
  fully_resolved_text = mkdocs_fences_to_pandoc(fully_resolved_text)
  local subdoc = parse_markdown(fully_resolved_text)
  return subdoc.blocks
end

---------------- Init ----------------
local function init_from_meta_and_env()
  if INITIALIZED then return end
  INITIALIZED = true

  local paths = {}
  local function add_path(p)
    p = pandoc.utils.stringify(p)
    if p and p ~= "" then paths[#paths+1] = expanduser(p) end
  end

  if META_RESOURCE_PATH then
    if type(META_RESOURCE_PATH) == "table" and META_RESOURCE_PATH.t == "MetaList" then
      for _,v in ipairs(META_RESOURCE_PATH) do add_path(v) end
    else
      local s = pandoc.utils.stringify(META_RESOURCE_PATH)
      local list_sep = is_windows() and ";" or ":"
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
    for _, p in ipairs(split(env_rp, list_sep)) do paths[#paths+1] = expanduser(p) end
  end

  paths[#paths+1] = "."

  local seen, norm = {}, {}
  for _, p in ipairs(paths) do if not seen[p] then seen[p]=true; norm[#norm+1]=p end end
  RESOURCE_PATHS = norm

  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    ROOT_DIR = dirname(PANDOC_STATE.input_files[1])
  else
    ROOT_DIR = "."
  end

  print("Starting include expansion (resolve_includes.lua)")
  print("Resource path search order:")
  for i, p in ipairs(RESOURCE_PATHS) do print(string.format("  [%d] %s", i, p)) end
  log("Root dir:", ROOT_DIR)
end

function Meta(meta)
  META_RESOURCE_PATH = meta["resource-path"] or meta["resourcepath"]
  return meta
end

---------------- Block handlers ----------------
local function expand_block_text(text)
  init_from_meta_and_env()
  local target = match_include_line(text)
  if not target then return nil end
  log("Matched include directive:", text)
  local blocks = blocks_from_include(target, ROOT_DIR)
  EXPANSIONS = EXPANSIONS + 1
  return blocks
end

local function maybe_expand_para_like(el)
  local text = inlines_text(el.content or {})
  return expand_block_text(text)
end

function Para(el)  return maybe_expand_para_like(el) or nil end
function Plain(el) return maybe_expand_para_like(el) or nil end

function RawBlock(el)
  -- Guard correctly: require el.text and then test patterns.
  if el.text and (el.text:find("{%%") or el.text:find("^@include")) then
    local blk = expand_block_text(el.text)
    if blk then return blk end
  end
  return nil
end

-- Some Pandoc versions wrap the raw line into a Div { .raw }.
function Div(el)
  if #el.content == 1 and el.content[1].t == "RawBlock" then
    local rb = el.content[1]
    if rb.text and (rb.text:find("{%%") or rb.text:find("^@include")) then
      local blk = expand_block_text(rb.text)
      if blk then return blk end
    end
  end
  return nil
end

---------------- Fallback: whole-doc pre-read ----------------
function Pandoc(doc)
  -- If paragraph-level expansion caught nothing, re-read top file and expand.
  if EXPANSIONS > 0 then
    log("AST pass expanded", EXPANSIONS, "include(s); no fallback needed.")
    return doc
  end
  init_from_meta_and_env()

  -- Must have a real input file to pre-read.
  if not (PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0) then
    log("No input file available; skipping fallback.")
    return doc
  end
  local top = PANDOC_STATE.input_files[1]
  local f = io.open(top, "rb")
  if not f then
    print("resolve_includes.lua fallback: cannot open top-level file: " .. tostring(top))
    return doc
  end
  local raw = f:read("*a"); f:close()
  print("Fallback: expanding includes from raw text of " .. top)
  local resolved = resolve_includes_text(raw, 0, dirname(top))
  resolved = mkdocs_fences_to_pandoc(resolved)
  local parsed = parse_markdown(resolved)
  return parsed
end
