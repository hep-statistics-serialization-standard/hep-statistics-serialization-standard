#!/usr/bin/env bash
# Check that everyone in the git history (commit authors and Co-authored-by
# trailers, normalised through .mailmap) is listed in markdown.yaml, either
# under `author:` (the committee) or under `contributors:`, unless they are
# deliberately excluded via tools/contributors-exclude.txt (pseudonymous authors).
#
#   tools/check_contributors.sh          # report missing names, exit 1 if any
#   tools/check_contributors.sh --write  # append missing names to `contributors:`
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
META="$ROOT/markdown.yaml"
EXCLUDE="$ROOT/tools/contributors-exclude.txt"   # pseudonymous authors, not listed

git_names() {
  {
    git -C "$ROOT" log --format='%aN <%aE>'
    git -C "$ROOT" log --format='%(trailers:key=Co-authored-by,valueonly)' \
      | grep -v '^$' | git -C "$ROOT" check-mailmap --stdin
  } | grep -viE 'noreply@anthropic\.com|\[bot\]' \
    | sed -E 's/ *<[^>]*>$//' | sort -u \
    | grep -vxFf <(grep -v '^#' "$EXCLUDE" | sed '/^$/d')
}

listed_names() {
  awk '
    /^[A-Za-z_-]+:/ { sec = $1 }
    (sec == "author:" || sec == "contributors:") && /^[ \t]*- / {
      sub(/^[ \t]*- */, ""); gsub(/[ \t]+/, " "); sub(/ $/, ""); print
    }' "$META" | sort -u
}

missing=$(comm -23 <(git_names) <(listed_names))

if [ -z "$missing" ]; then
  echo "markdown.yaml: all git contributors are listed."
  exit 0
fi

if [ "${1:-}" = "--write" ]; then
  tmp=$(mktemp)
  awk -v names="$missing" '
    BEGIN { n = split(names, add, "\n") }
    /^[A-Za-z_-]+:/ {
      if (in_contrib) { for (i = 1; i <= n; i++) print "  - " add[i]; in_contrib = 0 }
      if ($1 == "contributors:") in_contrib = 1
    }
    { print }
    END { if (in_contrib) for (i = 1; i <= n; i++) print "  - " add[i] }
  ' "$META" > "$tmp" && mv "$tmp" "$META"
  echo "Added to contributors in markdown.yaml:"; echo "$missing" | sed 's/^/  /'
  exit 0
fi

echo "The following git contributors are missing from markdown.yaml:" >&2
echo "$missing" | sed 's/^/  /' >&2
echo "Add them under 'contributors:' (or run: tools/check_contributors.sh --write)." >&2
exit 1
