# hooks/strip_front_matter.py
import re

# Remove a leading YAML front-matter block: --- ... ---
def on_page_markdown(markdown: str, **kwargs) -> str:
    return re.sub(r"\A---\s*\n.*?\n---\s*\n?", "", markdown, flags=re.DOTALL)
