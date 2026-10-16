#!/usr/bin/env bash
# Publish SSHD2382 course site to GitHub Pages.
# Repo: https://github.com/Lazaruschan/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-
#
# Usage:
#   cd Github/SSHD2382
#   ./publish.sh
#
# Use a GitHub Personal Access Token when asked for "Password" (not your account password).
# After push: Settings → Pages → Deploy from branch → main / (root)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

REPO_URL="https://github.com/Lazaruschan/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-.git"
BRANCH="main"
REMOTE="origin"

echo "==> Publishing from: $ROOT"
echo "==> Target: $REPO_URL"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed. Install Xcode CLT or Git first."
  exit 1
fi

if [[ ! -d .git ]]; then
  echo "==> git init"
  git init
fi

# Keep ignore list current
cat > .gitignore <<'EOF'
node_modules/
.DS_Store
*.log
*.rtf
start.rtf
.env
.env.*
*token*
*secret*
.slide-stage/
.worksheet-stage/
EOF

# Remove secret-prone files from disk if present
rm -f start.rtf *.rtf 2>/dev/null || true

echo "==> Staging site files only (explicit allow-list)"
git add --force \
  .gitignore \
  .nojekyll \
  README.md \
  index.html \
  auth.js \
  assets \
  slides \
  publish.sh \
  publish.bat \
  export-slides.sh \
  export-slides.py \
  export-worksheets.py \
  embed-slide-assets.py \
  package.json \
  package-lock.json

# Never publish secrets / tooling junk
git rm -r --cached node_modules 2>/dev/null || true
git rm --cached start.rtf 2>/dev/null || true
git rm --cached -f *.rtf 2>/dev/null || true
git rm -r --cached .slide-stage 2>/dev/null || true

echo "==> Staged files:"
git status --short | head -80

if git diff --cached --quiet; then
  if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "Error: nothing to commit and no previous commits."
    exit 1
  fi
  echo "==> No new changes; will push existing commits."
else
  echo "==> Committing"
  git commit -m "$(cat <<'EOF'
Publish SSHD2382 Design Fundamentals course website.

EOF
)"
fi

git branch -M "$BRANCH"

if git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "==> Updating remote $REMOTE"
  git remote set-url "$REMOTE" "$REPO_URL"
else
  echo "==> Adding remote $REMOTE"
  git remote add "$REMOTE" "$REPO_URL"
fi

echo "==> Pushing to $REMOTE/$BRANCH"
git push -u "$REMOTE" "$BRANCH"

PAGES_URL="https://lazaruschan.github.io/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-/"
echo ""
echo "Done."
echo "Enable Pages (once): repo Settings → Pages → Deploy from branch → main / (root)"
echo "Site URL: $PAGES_URL"
echo "Site password: 20262382"
