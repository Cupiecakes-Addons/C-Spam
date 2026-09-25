#!/usr/bin/env bash
# Build dist/C-Spam-v<version>.zip and dist/release.json for World of Warcraft.
#
# The zip contains a single C-Spam/ folder; extract it into
#   Windows: C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\
#   macOS:   /Applications/World of Warcraft/_retail_/Interface/AddOns/
#
# For WowUp compatibility, GitHub releases must include:
#   1. C-Spam-v<version>.zip (versioned filename so WowUp detects updates)
#   2. release.json (BigWigs metadata format mapping flavor to filename)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep '^## Version:' C-Spam.toc | head -1 | awk '{print $3}')
INTERFACE=$(grep '^## Interface:' C-Spam.toc | head -1 | awk '{print $3}')

if [ -z "$VERSION" ]; then
    echo "Error: Could not extract Version from C-Spam.toc" >&2
    exit 1
fi

if [ -z "$INTERFACE" ]; then
    echo "Error: Could not extract Interface from C-Spam.toc" >&2
    exit 1
fi

ARCHIVE_NAME="C-Spam-v${VERSION}.zip"
echo "Packaging C-Spam version v${VERSION} (Interface ${INTERFACE})..."

rm -rf dist
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
    --exclude '*.bak*' \
    --exclude 'Media/*.png' \
    --exclude 'Media/*.jpg' \
    --exclude 'Media/icon_64.tga' \
    ./ dist/C-Spam/

(cd dist && zip -rq "${ARCHIVE_NAME}" C-Spam)
cp "dist/${ARCHIVE_NAME}" dist/C-Spam.zip

cat > dist/release.json <<EOF
{"releases":[{"name":"C-SPAM [Chat Intercept System]","version":"v${VERSION}","filename":"${ARCHIVE_NAME}","nolib":false,"metadata":[{"flavor":"mainline","interface":${INTERFACE}}]}]}
EOF

echo "Built dist/${ARCHIVE_NAME} and dist/release.json:"
unzip -l "dist/${ARCHIVE_NAME}" | head -20
echo ""
echo "Contents of dist/release.json:"
cat dist/release.json
echo ""
