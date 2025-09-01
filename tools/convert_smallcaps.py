# hooks/convert_smallcaps.py
import re

# Rewrite Pandoc-style smallcaps [text]{.smallcaps} to an HTML span
def on_page_markdown(markdown: str, **kwargs) -> str:
    return re.sub(r'\[([^\]]+)\]\{\.smallcaps\}', r'<span class="smallcaps">\1</span>', markdown)
