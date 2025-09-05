"""
MkDocs hook to generate Sphinx objects.inv file during build.
Uses page.toc.items to access TOC data parsed by MkDocs.
"""

import zlib
from pathlib import Path
from typing import List


# Global storage for page data
_pages_data = []


def on_page_content(html, page, config, **kwargs):
    """Extract TOC data from page.toc after content processing."""
    global _pages_data
    
    def walk_toc(items):
        """Recursively walk TOC items to extract all anchors."""
        anchors = []
        for item in items:
            anchors.append({
                'id': item.id,
                'title': item.title,
                'url': item.url
            })
            # Recursively process children
            if item.children:
                anchors.extend(walk_toc(item.children))
        return anchors
    
    # Extract all anchors from the page's TOC
    anchors = walk_toc(page.toc.items) if page.toc and page.toc.items else []
    
    # Store page data for later use in on_post_build
    _pages_data.append({
        'page': page,
        'anchors': anchors,
        'url': page.url
    })
    
    return html


def on_post_build(config, **kwargs):
    """Generate objects.inv after the site is built."""
    output_path = Path(config['site_dir']) / 'objects.inv'
    _write_objects_inv(output_path, config)


def _write_objects_inv(output_path: Path, config):
    """Write the objects.inv file."""
    global _pages_data
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    inventory_lines = []
    site_url = config.get('site_url', '')
    if site_url and not site_url.endswith('/'):
        site_url += '/'
    
    for page_data in _pages_data:
        page = page_data['page']
        anchors = page_data['anchors']
        page_url = page_data['url']
        
        # Add the page itself as a document
        doc_name = page.file.src_path.replace('.md', '').replace('/', '.')
        inventory_lines.append(f"{doc_name} py:module 1 {page_url} -")
        
        # Add sections from TOC
        for anchor in anchors:
            anchor_id = anchor['id']
            anchor_title = anchor['title']
            
            # Create a reference name like "hs3.functions" from the section ID
            ref_name = f"hs3.{anchor_id}"
            anchor_url = f"{page_url}#{anchor_id}"
            
            # Add as a label (section reference)
            inventory_lines.append(f"{ref_name} std:label 1 {anchor_url} {anchor_title}")
    
    # Write the objects.inv file
    inventory_data = '\n'.join(inventory_lines) + '\n'
    
    with open(output_path, 'wb') as f:
        # Write header
        project_name = config.get('site_name', 'Documentation')
        version = '1.0'  # Could make this configurable
        
        header = f"# Sphinx inventory version 2\n"
        header += f"# Project: {project_name}\n"
        header += f"# Version: {version}\n"
        header += f"# The remainder of this file is compressed using zlib.\n"
        f.write(header.encode('utf-8'))
        
        # Compress and write inventory data
        compressed = zlib.compress(inventory_data.encode('utf-8'))
        f.write(compressed)
    
    print(f"Generated objects.inv with {len(inventory_lines)} entries at {output_path}")
    
    # Clear the global data for next build
    _pages_data.clear()