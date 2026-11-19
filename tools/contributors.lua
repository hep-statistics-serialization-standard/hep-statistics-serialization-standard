-- Render the `contributors` metadata list (from markdown.yaml) as a paragraph
-- right after the title block, in every output format.
function Meta(m)
  if not m.contributors then return m end
  local names = {}
  for _, c in ipairs(m.contributors) do
    table.insert(names, pandoc.utils.stringify(c))
  end
  m["include-before"] = pandoc.Para({
    pandoc.Strong({ pandoc.Str("Contributors:") }), pandoc.Space(),
    pandoc.Str(table.concat(names, ", "))
  })
  return m
end
