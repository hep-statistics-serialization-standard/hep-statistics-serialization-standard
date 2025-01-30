all: pdf html

pdf: hs3.pdf
html: hs3.html

hs3.pdf: main.md chapters/*.md parts/*.md tools/*.lua tools/*.tex
	pandoc main.md -o hs3.pdf --metadata-file=markdown.yaml --bibliography ./hs3.bib --include-in-header=tools/pandoc-header.tex --lua-filter=tools/resolve_includes.lua --citeproc --metadata link-citations=true --from=markdown+tex_math_dollars

hs3.html: main.md chapters/*.md parts/*.md tools/*.lua tools/*.html
	pandoc main.md -o hs3.html --metadata-file=markdown.yaml --bibliography ./hs3.bib --lua-filter=tools/resolve_includes.lua --citeproc --metadata link-citations=true --template tools/template.html
