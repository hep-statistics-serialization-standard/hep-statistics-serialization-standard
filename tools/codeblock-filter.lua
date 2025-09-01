-- Convert fenced code blocks with title="..." (or caption="...")
-- into captioned listings (LaTeX) or figure-like blocks (HTML).

local function latex_escape(s)
  -- Minimal escaping for captions.
  local map = {
    ["\\"] = "\\textbackslash{}",
    ["%"]  = "\\%",
    ["$"]  = "\\$",
    ["#"]  = "\\#",
    ["_"]  = "\\_",
    ["&"]  = "\\&",
    ["^"]  = "\\^{}",
    ["~"]  = "\\textasciitilde{}",
  }
  return (s:gsub("[\\%%%$#_%^&~]", map))
end

function CodeBlock(el)
  -- Accept either title= or caption=
  local title = (el.attributes and (el.attributes.title or el.attributes.caption)) or nil
  if not title then return nil end

  local id   = el.identifier
  local lang = (#el.classes > 0) and el.classes[1] or nil

  if FORMAT:match("latex") then
    -- Render via listings. Requires pandoc --listings (which you already use).
    local opts = {}
    if lang and lang ~= "" then table.insert(opts, "language=" .. lang) end
    if id and id ~= "" then table.insert(opts, "label={" .. id .. "}") end
    table.insert(opts, "caption={" .. latex_escape(title) .. "}")

    local head = "\\begin{lstlisting}[" .. table.concat(opts, ",") .. "]\n"
    local tail = "\n\\end{lstlisting}\n"
    return pandoc.RawBlock("latex", head .. el.text .. tail)

  elseif FORMAT:match("html") then
    -- <figure>   <figcaption>Title</figcaption> <pre><code>...</code></pre>  </figure>
    local cap  = pandoc.RawBlock("html", "<figcaption>" .. pandoc.text.escape(title, true) .. "</figcaption>")
    local pre  = pandoc.RawBlock("html", "<pre><code class=\"" ..
                                         table.concat(el.classes or {}, " ") .. "\">" ..
                                         pandoc.text.escape(el.text, true) ..
                                         "</code></pre>")
    local open = pandoc.RawBlock("html", "<figure class=\"code-with-caption\"" ..
                                         (id and id ~= "" and (" id=\""..id.."\"") or "") .. ">")
    local close = pandoc.RawBlock("html", "</figure>")
    return { open, cap, pre, close }

  else
    -- Fallback for other writers: show a simple caption paragraph above the code.
    local cap = pandoc.Para({ pandoc.Emph{ pandoc.Str(title) } })
    return { cap, el }
  end
end
