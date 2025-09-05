-- tools/mkdocs-bib-placeholder.lua
-- Replace a lone "\bibliography" (or "\bibliography{}") marker with:
--  - a Div #refs (class "references") for HTML/Markdown targets (so --citeproc prints there)
--  - a raw LaTeX \printbibliography for LaTeX/PDF targets (for biblatex+biber)
--
-- This lets you keep a single source that works for both MkDocs (HTML) and Pandoc→LaTeX (PDF).

local function is_bib_command(s)
  if not s then return false end
  -- tolerate whitespace; accept \bibliography and \bibliography{}
  s = s:gsub("%s+", "")
  return (s == "\\bibliography" or s == "\\bibliography{}")
end

local function bib_node_for_target()
  -- FORMAT is a global set by pandoc
  if FORMAT:match("latex") or FORMAT:match("beamer") then
    -- For LaTeX output, let biblatex handle it:
    return nil
  else
    -- For HTML/other: produce a #refs placeholder for pandoc --citeproc
    return pandoc.Div({}, pandoc.Attr("refs", {"references"}, {}))
  end
end

function Para(el)
  if #el.content == 1 then
    local x = el.content[1]
    if x.t == "RawInline" and (x.format == "tex" or x.format == "latex") and is_bib_command(x.text) then
      return { bib_node_for_target() }
    end
    if x.t == "Str" and is_bib_command(x.text) then
      return { bib_node_for_target() }
    end
  end
  return nil
end

function RawBlock(el)
  if (el.format == "tex" or el.format == "latex") and is_bib_command(el.text) then
    return bib_node_for_target()
  end
  return nil
end
