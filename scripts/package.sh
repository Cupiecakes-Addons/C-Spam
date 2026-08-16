#!/usr/bin/env bash
# Build dist/C-Spam.zip — a drop-in package for World of Warcraft.
#
# The zip contains a single C-Spam/ folder; extract it into
#   Windows: C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\
#   macOS:   /Applications/World of Warcraft/_retail_/Interface/AddOns/
#
# Official releases are built by .github/workflows/release.yml on tag push;
# this script produces the same layout locally for testing.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf dist/C-Spam dist/C-Spam.zip
mkdir -p dist/C-Spam

rsync -a \
    --exclude '.git' \
    --exclude '.github' \
    --exclude '.gitignore' \
    --exclude '.pkgmeta' \
    --exclude '.DS_Store' \
    --exclude 'dist' \
    --exclude 'scripts' \
    --exclude 'tests' \
    ./ dist/C-Spam/

(cd dist && zip -rq C-Spam.zip C-Spam)
echo "Built dist/C-Spam.zip:"
unzip -l dist/C-Spam.zip | head -20
