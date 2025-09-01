all: pdf html

pdf: hs3.pdf
html: hs3.html

hs3.pdf: docs/main.md docs/chapters/*.md docs/parts/*.md tools/*.lua tools/*.tex
	export PANDOC_RESOURCE_PATH="docs" && pandoc docs/main.md -o hs3.pdf --metadata-file=markdown.yaml --listings --bibliography ./docs/hs3.bib --include-in-header=tools/pandoc-header.tex --lua-filter=tools/resolve_includes.lua --lua-filter=tools/root-relative.lua --citeproc --metadata link-citations=true --from=markdown+tex_math_dollars+fenced_code_blocks+fenced_code_attributes --resource-path "$$PANDOC_RESOURCE_PATH"

hs3.html: docs/main.md docs/chapters/*.md docs/parts/*.md tools/*.lua tools/*.html
	export PANDOC_RESOURCE_PATH="docs" && pandoc docs/main.md -o hs3.html --metadata-file=markdown.yaml --listings --bibliography ./docs/hs3.bib --lua-filter=tools/resolve_includes.lua --lua-filter=tools/root-relative.lua --citeproc --metadata link-citations=true --template tools/template.html --from=markdown+tex_math_dollars+fenced_code_blocks+fenced_code_attributes --resource-path="$$PANDOC_RESOURCE_PATH"

clean:
	rm -f hs3.pdf hs3.html
