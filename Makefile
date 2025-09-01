all: pdf html

pdf: hs3.pdf
html: hs3.html

pandoc-container: Dockerfile
	DOCKER_BUILDKIT=1 docker build -t pdf-builder .


hs3.pdf: docs/main.md docs/chapters/*.md docs/parts/*.md tools/*.lua tools/*.tex
	export PANDOC_RESOURCE_PATH="docs" && pandoc docs/main.md -o hs3.pdf  --metadata-file=markdown.yaml --listings --bibliography ./docs/hs3.bib --lua-filter=tools/resolve_includes.lua --lua-filter=tools/root-relative.lua --lua-filter=tools/mkdocs-bib-placeholder.lua --include-in-header=tools/pandoc-header.tex --citeproc --metadata link-citations=true --from=markdown+tex_math_dollars+fenced_code_blocks+fenced_code_attributes+link_attributes+implicit_figures --resource-path "$$PANDOC_RESOURCE_PATH"

hs3.html: docs/main.md docs/chapters/*.md docs/parts/*.md tools/*.lua tools/*.html
	export PANDOC_RESOURCE_PATH="docs" && pandoc docs/main.md -o hs3.html --metadata-file=markdown.yaml --listings --bibliography ./docs/hs3.bib --lua-filter=tools/resolve_includes.lua --lua-filter=tools/root-relative.lua --lua-filter=tools/mkdocs-bib-placeholder.lua --template tools/template.html --citeproc --metadata link-citations=true --from=markdown+tex_math_dollars+fenced_code_blocks+fenced_code_attributes+link_attributes+implicit_figures --resource-path="$$PANDOC_RESOURCE_PATH"

clean:
	rm -f hs3.pdf hs3.html
