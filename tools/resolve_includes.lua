function strip_metadata(content)
  local stripped_content = ""
  local in_metadata = false

  for line in content:gmatch("([^\n]*)\n?") do
    -- Detect start of metadata block
    if line:match("^%-%-%-$") and not in_metadata then
      in_metadata = true
    elseif in_metadata and line:match("^%-%-%-$") then
      -- Detect end of metadata block and stop skipping
      in_metadata = false
    elseif not in_metadata then
      -- Only keep content outside metadata blocks
      stripped_content = stripped_content .. line .. "\n"
    end
  end

  return stripped_content
end


function resolve_includes(content, depth)
  depth = depth or 0
  local indent = string.rep("  ", depth)
  local resolved_content = ""

  for line in content:gmatch("([^\n]*)\n?") do
    local include_file = line:match('@include:?%s*["“”]?[^A-Za-z0-9._/]*([A-Za-z0-9._/]+)[^A-Za-z0-9._/]*["“”]?')
    if include_file then
      print(indent .. "Found include directive for file: " .. include_file)
      local file = io.open(include_file, "r")
      if file then
        local included_content = file:read("*a")
        file:close()
        print(indent .. "Successfully read file: " .. include_file)
        -- Strip metadata from the included content
        local stripped_content = strip_metadata(included_content)
        -- Recursively resolve includes in the included content
        local resolved_included_content = resolve_includes(stripped_content, depth + 1)
        resolved_content = resolved_content .. resolved_included_content .. "\n"
      else
        print(indent .. "Missing include file: " .. include_file)
        resolved_content = resolved_content .. "% Missing include: " .. include_file .. "\n"
      end
    else
      resolved_content = resolved_content .. line .. "\n"
    end
  end

  return resolved_content
end

function process_blocks(blocks, depth)
  local resolved_blocks = {}
  for _, block in ipairs(blocks) do
    if block.t == "Para" then
      local text = pandoc.utils.stringify(block)
      local resolved_content = resolve_includes(text, depth)
      local parsed_blocks = pandoc.read(resolved_content, "markdown").blocks
      for _, parsed_block in ipairs(parsed_blocks) do
        table.insert(resolved_blocks, parsed_block)
      end
    else
      table.insert(resolved_blocks, block)
    end
  end
  return resolved_blocks
end

function Pandoc(doc)
  print("Starting document assembly...")

  -- Process all blocks in the document
  local resolved_blocks = process_blocks(doc.blocks, 0)

  print("Finished document assembly.")
  return pandoc.Pandoc(resolved_blocks, doc.meta)
end
