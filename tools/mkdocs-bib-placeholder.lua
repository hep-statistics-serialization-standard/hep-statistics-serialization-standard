-- Replace a lone "\bibliography" (or "\bibliography{}") line with a Div #refs
-- so pandoc --citeproc places the bibliography at that position.
-- Leaves your source untouched for MkDocs.

local function is_bib_command(s)
  if not s then return false end
  -- tolerate whitespace; accept \bibliography and \bibliography{}
  s = s:gsub("%s+", "")
  return (s == "\\bibliography" or s == "\\bibliography{}")
end

function Para(el)
  if #el.content == 1 then
    local x = el.content[1]
    if x.t == "RawInline" and (x.format == "tex" or x.format == "latex") and is_bib_command(x.text) then
      -- Replace the whole paragraph with a refs div
      return { pandoc.Div({}, pandoc.Attr("refs", {"references"}, {})) }
    end
    if x.t == "Str" and is_bib_command(x.text) then
      return { pandoc.Div({}, pandoc.Attr("refs", {"references"}, {})) }
    end
  end
  return nil
end

function RawBlock(el)
  if (el.format == "tex" or el.format == "latex") and is_bib_command(el.text) then
    return pandoc.Div({}, pandoc.Attr("refs", {"references"}, {}))
  end
  return nil
end
