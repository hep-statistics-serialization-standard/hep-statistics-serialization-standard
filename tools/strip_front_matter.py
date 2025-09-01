# hooks/strip_front_matter.py
import re

# Remove any YAML-style front matter block '--- ... ---' that appears at a line start
def on_page_markdown(markdown: str, **kwargs) -> str:
    return re.sub(r"(?ms)^(?:\ufeff)?---\s*\n.*?\n---\s*\n?", "", markdown)
