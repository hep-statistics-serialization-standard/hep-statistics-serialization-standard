-- tools/codeblock-filter.lua
-- Recover inline code-fence titles like: ```json title="Example: …"
-- Pandoc tokenizes info string into classes; title may be split across tokens.

local function extract_inline_title(classes)
  local kept, found_title = {}, nil
  local i, n = 1, #classes
  while i <= n do
    local c = classes[i]

    -- Detect title="... or title='...
    local q = c:match('^title=(["\'])')
    if q then
      local acc = c:match('^title=['..q..'](.*)$') or ""
      -- closed on same token?
      if acc:sub(-1) == q then
        acc = acc:sub(1, -2)
        found_title = acc
      else
        i = i + 1
        while i <= n do
          local c2 = classes[i]
          acc = acc .. " " .. c2
          if c2:sub(-1) == q then
            acc = acc:sub(1, -2)
            found_title = acc
            break
          end
          i = i + 1
        end
      end
      -- do not keep the consumed title tokens
    else
      -- Bare form: title=NoSpaces
      local bare = c:match('^title=([^%s]+)$')
      if bare and not found_title then
        found_title = bare
      else
        kept[#kept+1] = c
      end
    end
    i = i + 1
  end
  return found_title, kept
end

local function get_attr(el)
  -- Pandoc 2.x: identifier/classes/attributes; Pandoc 3.x: el.attr
  if el.attr then
    return el.attr
  else
    return {
      identifier = el.identifier or "",
      classes    = el.classes or {},
      attributes = el.attributes or {}
    }
  end
end

local function set_attr(el, attr)
  if el.attr then
    el.attr = attr
  else
    el.identifier = attr.identifier
    el.classes    = attr.classes
    el.attributes = attr.attributes
  end
end

function CodeBlock(el)
  local attr = get_attr(el)

  -- If someone already gave us a title/caption, keep it
  local title = (attr.attributes and (attr.attributes.caption or attr.attributes.title)) or nil

  -- Otherwise try to recover from classes
  if not title then
    local t, kept = extract_inline_title(attr.classes or {})
    if t then
      title = t
      attr.classes = kept
    end
  end

  if title then
    attr.attributes = attr.attributes or {}
    -- set both: some outputs key off caption; others might use title
    attr.attributes.title   = title
    attr.attributes.caption = title
    set_attr(el, attr)
  end

  return el
end
