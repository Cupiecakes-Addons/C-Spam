#!/usr/bin/env bash
# Build dist/C-Spam-v<version>.zip and dist/release.json for World of Warcraft.
#
# The zip contains a single C-Spam/ folder and loads on every client listed in
# the TOC's "## Interface:" line. Extract it into that client's AddOns folder:
#   Retail:  World of Warcraft\_retail_\Interface\AddOns\
#   Forever: World of Warcraft\_forever_\Interface\AddOns\
#
# For WowUp compatibility, GitHub releases must include:
#   1. C-Spam-v<version>.zip (versioned filename so WowUp detects updates)
#   2. release.json (BigWigs metadata format mapping each flavor to that zip)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep '^## Version:' C-Spam.toc | head -1 | awk '{print $3}')
# Every interface number on the line, e.g. "120105, 16001" -> "120105 16001"
INTERFACES=$(grep '^## Interface:' C-Spam.toc | head -1 | sed -e 's/^## Interface://' -e 's/\r//g' | tr ',' ' ' | xargs)

if [ -z "$VERSION" ]; then
    echo "Error: Could not extract Version from C-Spam.toc" >&2
    exit 1
fi

if [ -z "${INTERFACES// /}" ]; then
    echo "Error: Could not extract Interface from C-Spam.toc" >&2
    exit 1
fi

# One release.json metadata entry per interface number. Flavor names are the
# ones the BigWigs packager writes and WowUp matches on: "mainline" for Retail,
# "forever" for WoW Forever (16xxx). Anything else is refused rather than
# guessed, because a wrong flavor installs this zip on a client it was never
# checked against.
METADATA=""
for INTERFACE in $INTERFACES; do
    case "$INTERFACE" in
        16[0-9][0-9][0-9]) FLAVOR="forever" ;;
        [1-9][0-9][0-9][0-9][0-9][0-9]) FLAVOR="mainline" ;;
        *)
            echo "Error: no release.json flavor for interface ${INTERFACE}; add one to scripts/package.sh" >&2
            exit 1
            ;;
    esac
    METADATA="${METADATA:+${METADATA},}{\"flavor\":\"${FLAVOR}\",\"interface\":${INTERFACE}}"
done

ARCHIVE_NAME="C-Spam-v${VERSION}.zip"
echo "Packaging C-Spam version v${VERSION} (Interface ${INTERFACES// /, })..."

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
{"releases":[{"name":"C-SPAM [Chat Intercept System]","version":"v${VERSION}","filename":"${ARCHIVE_NAME}","nolib":false,"metadata":[${METADATA}]}]}
EOF

echo "Built dist/${ARCHIVE_NAME} and dist/release.json:"
unzip -l "dist/${ARCHIVE_NAME}" | head -20
echo ""
echo "Contents of dist/release.json:"
cat dist/release.json
echo ""
