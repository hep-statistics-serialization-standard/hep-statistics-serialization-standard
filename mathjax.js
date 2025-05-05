
        MathJax = {
            tex: {
                macros: {
                    ensuremath: ["{{#1}}", 1],
                    boldsymbol: ["\\mathbf{#1}", 1]
                },
                inlineMath: [['$', '$'], ['\\(', '\\)']],
                displayMath: [['$$', '$$'], ['\\[', '\\]']]
            },
            options: {
                processHtmlClass: "mathjax",
                ignoreHtmlClass: "no-mathjax"
            }
        };
