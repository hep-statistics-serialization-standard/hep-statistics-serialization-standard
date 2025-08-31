-- tools/codeblock-filter.lua
-- Reconstruct inline code fence titles like: ```json title="Example: Foo"
-- Pandoc tokenizes them into classes: 'title="Example:' 'Foo"'
-- We gather tokens until the closing quote and set a proper attribute.

local function extract_inline_title(classes)
  local new_classes = {}
  local found_title = nil
  local i = 1
  while i <= #classes do
    local c = classes[i]
    -- match title=..., optionally with opening quote
    local q = c:match('^title=(["\'])')           -- quote char " or ' if present
    local rest
    if q then
      rest = c:match('^title=['..q..'](.*)$')     -- content after opening quote
      local acc = rest or ""
      -- already closed on same token?
      if acc:sub(-1) == q then
        acc = acc:sub(1, -2)                      -- strip trailing quote
        found_title = acc
      else
        -- accumulate subsequent class tokens until one ends with the quote
        i = i + 1
        while i <= #classes do
          local c2 = classes[i]
          acc = acc .. " " .. c2
          if c2:sub(-1) == q then
            acc = acc:sub(1, -2)                  -- strip trailing quote
            found_title = acc
            break
          end
          i = i + 1
        end
      end
      -- do not keep any of the consumed title parts in classes
    else
      -- also handle the bare form: title=NoSpaces
      local bare = c:match('^title=([^%s]+)$')
      if bare and not found_title then
        found_title = bare
      else
        table.insert(new_classes, c)
      end
    end
    i = i + 1
  end
  return found_title, new_classes
end

function CodeBlock(el)
  local classes = el.attr and el.attr.classes or {}
  local title, kept = extract_inline_title(classes)
  if title then
    el.attr.classes = kept
    el.attr.attributes = el.attr.attributes or {}
    -- EITHER set a non-rendered attribute 'title':
    el.attr.attributes.title = title
    -- OR, if you want visible captions in PDF/HTML, set 'caption' instead:
    -- el.attr.attributes.caption = title
  end
  return el
end
