all: pdf html

pdf: hs3.pdf
html: hs3.html

pandoc-container: Dockerfile
	DOCKER_BUILDKIT=1 docker build -t pdf-builder .

hs3.pdf: hs3.tex
	TEXINPUTS=docs: BIBINPUTS=docs: BSTINPUTS=docs: xelatex hs3.tex
	TEXINPUTS=docs: BIBINPUTS=docs: BSTINPUTS=docs: biber hs3
	TEXINPUTS=docs: BIBINPUTS=docs: BSTINPUTS=docs: xelatex hs3.tex
	TEXINPUTS=docs: BIBINPUTS=docs: BSTINPUTS=docs: xelatex hs3.tex

hs3.tex: docs/index.md docs/chapters/*.md docs/parts/*.md tools/*.lua tools/*.tex
	export PANDOC_RESOURCE_PATH="docs" && pandoc docs/index.md -o hs3.tex  --metadata-file=markdown.yaml --listings --pdf-engine=xelatex --biblatex --lua-filter=tools/resolve_includes.lua --lua-filter=tools/root-relative.lua --lua-filter=tools/mkdocs-bib-placeholder.lua --include-in-header=tools/pandoc-header.tex --metadata link-citations=true --from=markdown+tex_math_dollars+fenced_code_blocks+fenced_code_attributes+link_attributes+implicit_figures --resource-path "$$PANDOC_RESOURCE_PATH" -t latex

hs3.html: docs/index.md docs/chapters/*.md docs/parts/*.md tools/*.lua tools/*.html
	export PANDOC_RESOURCE_PATH="docs" && pandoc docs/index.md -o hs3.html --metadata-file=markdown.yaml --listings --bibliography ./docs/hs3.bib --lua-filter=tools/resolve_includes.lua --lua-filter=tools/root-relative.lua --lua-filter=tools/mkdocs-bib-placeholder.lua --template tools/template.html --citeproc --metadata link-citations=true --from=markdown+tex_math_dollars+fenced_code_blocks+fenced_code_attributes+link_attributes+implicit_figures --resource-path="$$PANDOC_RESOURCE_PATH"

clean:
	rm -f hs3.pdf hs3.html hs3.tex *.log *.bbl *.bcf *.blg

docs/files/hs3.pdf: hs3.pdf
	mkdir -p docs/files
	cp hs3.pdf docs/files

.venv/bin/activate:
	python3 -m venv .venv && . .venv/bin/activate && pip install --upgrade pip && pip install -r mkdocs-requirements.txt

local-serve: docs/files/hs3.pdf .venv/bin/activate
	source .venv/bin/activate && mkdocs serve --strict
