#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  video-share /path/to/video
  echo /path/to/video | video-share

Environment variables:
  SHARE_SSH_HOST_ALIAS   SSH host alias (default: fxwin-vps)
  SHARE_REMOTE_DIR       Remote upload dir (default: /srv/videos/public)
  SHARE_BASE_URL         Public base URL (default: https://videos.fxwin.net/raw)
EOF
}

fail() {
  echo "Error: $*" >&2
  notify_error "$*"
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fail "Missing required command: $cmd"
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

shell_quote() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

notify_info() {
  local message="$1"
  if command -v kdialog >/dev/null 2>&1; then
    kdialog --title "Share via VPS" --passivepopup "$message" 5 >/dev/null 2>&1 &
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Share via VPS" "$message" >/dev/null 2>&1 || true
  fi
}

notify_error() {
  local message="$1"
  if command -v kdialog >/dev/null 2>&1; then
    kdialog --title "Share via VPS" --error "$message" >/dev/null 2>&1 &
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send --urgency=critical "Share via VPS" "$message" >/dev/null 2>&1 || true
  fi
}

copy_clipboard() {
  local value="$1"
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$value" | wl-copy
    return 0
  fi
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$value" | xclip -selection clipboard
    return 0
  fi
  if command -v xsel >/dev/null 2>&1; then
    printf '%s' "$value" | xsel --clipboard --input
    return 0
  fi
  return 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

file_path="${1:-}"
if [[ -z "$file_path" && ! -t 0 ]]; then
  IFS= read -r file_path || true
fi

file_path="$(trim "$file_path")"
[[ -n "$file_path" ]] || fail "No input path provided"
[[ -f "$file_path" ]] || fail "File not found: $file_path"

require_cmd ssh
require_cmd scp

: "${SHARE_SSH_HOST_ALIAS:=fxwin-vps}"
: "${SHARE_REMOTE_DIR:=/srv/videos/public}"
: "${SHARE_BASE_URL:=https://videos.fxwin.net/raw}"

quoted_dir="$(shell_quote "$SHARE_REMOTE_DIR")"

if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$SHARE_SSH_HOST_ALIAS" "true" >/dev/null 2>&1; then
  fail "SSH check failed for host alias '$SHARE_SSH_HOST_ALIAS' (is key auth/agent ready?)"
fi

if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$SHARE_SSH_HOST_ALIAS" "test -d '$quoted_dir' && test -w '$quoted_dir'" >/dev/null 2>&1; then
  fail "Remote directory is not writable or missing: $SHARE_REMOTE_DIR"
fi

if command -v openssl >/dev/null 2>&1; then
  id="$(openssl rand -base64 18 | tr -d '+/=\n' | cut -c1-22)"
else
  id="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 22)"
fi

name="$(basename -- "$file_path")"
ext=""
if [[ "$name" == *.* && "$name" != .* ]]; then
  ext=".${name##*.}"
elif [[ "$name" == .*.* ]]; then
  ext=".${name##*.}"
fi
new_name="${id}${ext}"

remote_path="${SHARE_SSH_HOST_ALIAS}:${SHARE_REMOTE_DIR%/}/${new_name}"

echo "Uploading $name ..." >&2
if ! scp -q -- "$file_path" "$remote_path"; then
  fail "Upload failed"
fi

link="${SHARE_BASE_URL%/}/${new_name}"
if copy_clipboard "$link"; then
  notify_info "Uploaded. Link copied to clipboard."
else
  notify_info "Uploaded. Clipboard tool missing; link printed to terminal."
fi

echo "$link"
