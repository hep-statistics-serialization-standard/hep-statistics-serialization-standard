-- tools/root-relative.lua
-- Strip a single leading '/' so --resource-path can resolve files.
local function strip_root(path)
  if type(path) == "string" and path:sub(1,1) == "/" and not path:match("^//") then
    return path:sub(2)
  end
  return path
end

-- Markdown images/links
function Image(el)
  el.src = strip_root(el.src)
  return el
end

function Link(el)
  el.target = strip_root(el.target)
  return el
end

-- Raw LaTeX and HTML (includegraphics, input/include, img/a)
local function fix_latex(s)
  s = s:gsub("\\includegraphics%s*(%b[])?%s*{%s*/([^}]+)}",
             "\\includegraphics%1{%2}")
  s = s:gsub("\\(include|input)%s*{%s*/([^}]+)}",
             "\\%1{%2}")
  return s
end

local function fix_html(s)
  s = s:gsub('(<img%s+[^>]-src=")/([^"]+)"', '%1%2"')
  s = s:gsub('(<a%s+[^>]-href=")/([^"]+)"', '%1%2"')
  return s
end

function RawInline(el)
  if el.format == "latex" then el.text = fix_latex(el.text) end
  if el.format == "html"  then el.text = fix_html(el.text)  end
  return el
end

function RawBlock(el)
  if el.format == "latex" then el.text = fix_latex(el.text) end
  if el.format == "html"  then el.text = fix_html(el.text)  end
  return el
end
