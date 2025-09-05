import os
import re

# Match Markdown images: ![alt](url "title"){attrs}
IMG = re.compile(r'!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)(\{[^}]*\})?')

# Order to try for the web build
WEB_EXTS = [".svg", ".png", ".jpg", ".jpeg", ".webp"]

def on_page_markdown(markdown, page, config, files, **kwargs):
    docs_dir = config["docs_dir"]

    def pick_ext(url):
        # Skip absolute/external/data URLs
        if "://" in url or url.startswith("data:"):
            return None

        # Strip query/fragment
        base_url = url.split("#", 1)[0].split("?", 1)[0]

        # Only touch paths under images/ (adjust if you use a different folder)
        if not (base_url.startswith("images/") or base_url.startswith("/images/")):
            return None

        # If it already has an extension, leave it
        name = os.path.basename(base_url)
        if "." in name:
            return None

        # Build a filesystem path for existence checks
        rel = base_url[1:] if base_url.startswith("/") else base_url

        for ext in WEB_EXTS:
            cand = os.path.join(docs_dir, rel + ext)
            if os.path.exists(cand):
                return url + ext  # preserve any original query/fragment by appending to the original url

        # No known web extension found → leave unchanged
        return None

    def repl(m):
        alt, url, attrs = m.group(1), m.group(2), m.group(3) or ""
        new_url = pick_ext(url)
        if new_url is None:
            return m.group(0)
        return f'![{alt}]({new_url}){attrs}'

    return IMG.sub(repl, markdown)
