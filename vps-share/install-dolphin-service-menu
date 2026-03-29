#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SOURCE_DIR}/video-share.desktop"
TARGET_PLASMA6="${HOME}/.local/share/kio/servicemenus"
TARGET_PLASMA5="${HOME}/.local/share/kservices5/ServiceMenus"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: service menu template not found: $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p "$TARGET_PLASMA6"
cp "$SOURCE_FILE" "$TARGET_PLASMA6/video-share.desktop"
chmod +x "$TARGET_PLASMA6/video-share.desktop"

mkdir -p "$TARGET_PLASMA5"
cp "$SOURCE_FILE" "$TARGET_PLASMA5/video-share.desktop"
chmod +x "$TARGET_PLASMA5/video-share.desktop"

echo "Installed service menu to:"
echo "  $TARGET_PLASMA6/video-share.desktop"
echo "  $TARGET_PLASMA5/video-share.desktop"
echo "If the menu does not show immediately, run: kbuildsycoca6 && killall dolphin && dolphin &"
