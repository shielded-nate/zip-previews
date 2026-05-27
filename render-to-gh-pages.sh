#!/usr/bin/env bash
# Renders ZIPs from all fork subtrees and publishes results to the gh-pages branch.
#
# Usage: ./render-to-gh-pages.sh
#
# Prerequisites (provided by `nix develop`):
#   rst2html5, pandoc, multimarkdown, perl, make, git, python3

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 1. Ensure the working tree is clean before doing anything
# ---------------------------------------------------------------------------
if ! git diff --quiet HEAD; then
    echo "Error: Working tree has unstaged changes. Please commit or stash them first." >&2
    exit 1
fi
if ! git diff --cached --quiet; then
    echo "Error: There are staged changes. Please commit or stash them first." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Record the current branch / commit we are building from
# ---------------------------------------------------------------------------
CURRENT_COMMIT=$(git rev-parse HEAD)
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

echo "Building from commit ${CURRENT_COMMIT}${CURRENT_BRANCH:+ (branch: $CURRENT_BRANCH)}"

# ---------------------------------------------------------------------------
# 3. Discover fork subtree directories (each must contain a Makefile)
#    Pattern: forks/<domain>/<org>/<repo>/<branch>/
# ---------------------------------------------------------------------------
mapfile -t FORK_DIRS < <(
    find forks -mindepth 2 -maxdepth 5 -name Makefile -exec dirname {} \; 2>/dev/null \
    | sort -u
)

if [ "${#FORK_DIRS[@]}" -eq 0 ]; then
    echo "No fork directories found under forks/. Nothing to render." >&2
    exit 0
fi

echo "Found ${#FORK_DIRS[@]} fork(s) to render:"
for d in "${FORK_DIRS[@]}"; do echo "  $d"; done

# ---------------------------------------------------------------------------
# 4. Render ZIPs for every fork
# ---------------------------------------------------------------------------
for fork_dir in "${FORK_DIRS[@]}"; do
    echo ""
    echo "==> Rendering $fork_dir ..."
    (cd "$fork_dir" && make all-zips)

    # make all-zips regenerates README.rst from the template; reset it so the
    # working tree stays clean for the upcoming branch operations.
    git checkout -- "$fork_dir/README.rst" 2>/dev/null || true
done

# Confirm the tree is still clean (only untracked / ignored files should remain)
if ! git diff --quiet HEAD; then
    echo "Error: Unexpected tracked-file changes after rendering. Aborting." >&2
    git diff --name-only HEAD >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 5. Reset (or create) the gh-pages branch at the current commit so it starts
#    as an exact copy of the current revision.
# ---------------------------------------------------------------------------
if git show-ref --verify --quiet refs/heads/gh-pages; then
    git branch -f gh-pages "$CURRENT_COMMIT"
else
    git branch gh-pages "$CURRENT_COMMIT"
fi

# ---------------------------------------------------------------------------
# 6. Switch to gh-pages
#    Untracked/ignored files (the rendered output) survive the checkout.
# ---------------------------------------------------------------------------
git checkout gh-pages

# ---------------------------------------------------------------------------
# 7. Disable Jekyll so GitHub Pages serves files verbatim (important for paths
#    containing underscores and for directory navigation).
# ---------------------------------------------------------------------------
touch .nojekyll

# ---------------------------------------------------------------------------
# 8. Generate a top-level index.html that lists all available fork renders
# ---------------------------------------------------------------------------
python3 - <<'PYEOF'
import os, html as html_mod

rendered_dirs = []
for dirpath, dirnames, _ in os.walk("forks"):
    dirnames.sort()
    if "rendered" in dirnames:
        rendered_dirs.append(dirpath)

rendered_dirs.sort()

lines = [
    "<!DOCTYPE html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\" />",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />",
    "  <title>ZIPomatic</title>",
    "  <style>",
    "    body { font-family: sans-serif; max-width: 800px; margin: 2em auto; padding: 0 1em; }",
    "    ul { line-height: 1.8; }",
    "  </style>",
    "</head>",
    "<body>",
    "  <h1>ZIPomatic</h1>",
    "  <p>Rendered ZIPs from multiple repositories and branches:</p>",
    "  <ul>",
]
for d in rendered_dirs:
    href = d.replace(os.sep, "/") + "/rendered/"
    label = html_mod.escape(d)
    lines.append(f'    <li><a href="{html_mod.escape(href)}">{label}</a></li>')
lines += [
    "  </ul>",
    "</body>",
    "</html>",
    "",
]
with open("index.html", "w") as f:
    f.write("\n".join(lines))
print("Generated index.html")
PYEOF

# ---------------------------------------------------------------------------
# 9. Stage the rendered output and the gh-pages helpers
# ---------------------------------------------------------------------------
for fork_dir in "${FORK_DIRS[@]}"; do
    if [ -d "$fork_dir/rendered" ]; then
        git add -f "$fork_dir/rendered"
    fi
done
git add .nojekyll index.html

# ---------------------------------------------------------------------------
# 10. Commit (skip if nothing changed)
# ---------------------------------------------------------------------------
if git diff --cached --quiet; then
    echo "Nothing new to commit."
else
    git commit -m "Render ZIPs to GitHub Pages from ${CURRENT_COMMIT}"
fi

# ---------------------------------------------------------------------------
# 11. Push gh-pages
# ---------------------------------------------------------------------------
git push origin gh-pages --force

echo ""
echo "Successfully published gh-pages."

# ---------------------------------------------------------------------------
# 12. Return to the original branch and clean up generated artefacts
# ---------------------------------------------------------------------------
if [ -n "$CURRENT_BRANCH" ]; then
    git checkout "$CURRENT_BRANCH"
fi

for fork_dir in "${FORK_DIRS[@]}"; do
    rm -rf "$fork_dir/rendered"
    rm -f \
        "$fork_dir/.Makefile.uptodate" \
        "$fork_dir/.zipfilelist.current" \
        "$fork_dir/.draftfilelist.current"
done
