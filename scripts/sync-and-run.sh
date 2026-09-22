#!/bin/sh
set -eu

PROGRAM_NAME="synology-bing-wallpaper-sync"
REPO_SLUG="${REPO_SLUG:-SiuKam/synology-bing-wallpaper}"
SYNC_REF="${SYNC_REF:-main}"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TARGET="$PROJECT_DIR/synology-bing-wallpaper.sh"
TMP_FILE="$PROJECT_DIR/.synology-bing-wallpaper.sh.tmp.$$"

log() {
    printf '[%s] %s\n' "$PROGRAM_NAME" "$*"
}

warn() {
    printf '[%s] WARNING: %s\n' "$PROGRAM_NAME" "$*" >&2
}

fail() {
    printf '[%s] ERROR: %s\n' "$PROGRAM_NAME" "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT INT TERM HUP

fetch() {
    url=$1
    output=$2

    if command_exists curl; then
        curl -fsSL --retry 5 --connect-timeout 15 --max-time 60 -o "$output" "$url"
    elif command_exists wget; then
        wget -t 5 -T 60 -qO "$output" "$url"
    else
        return 1
    fi
}

sync_ok=0

if command_exists git && [ -d "$PROJECT_DIR/.git" ]; then
    log "Syncing repository from GitHub..."
    if git -C "$PROJECT_DIR" pull --ff-only; then
        sync_ok=1
    else
        warn "git pull failed; using the last local version."
    fi
else
    raw_url="https://raw.githubusercontent.com/${REPO_SLUG}/${SYNC_REF}/synology-bing-wallpaper.sh"
    log "Syncing main script from GitHub..."

    if fetch "$raw_url" "$TMP_FILE" && [ -s "$TMP_FILE" ] && sh -n "$TMP_FILE"; then
        chmod 0755 "$TMP_FILE"
        mv -f "$TMP_FILE" "$TARGET"
        sync_ok=1
    else
        warn "Download or syntax validation failed; using the last local version."
    fi
fi

[ -f "$TARGET" ] || fail "No local wallpaper script is available at $TARGET."
sh -n "$TARGET" || fail "Local wallpaper script failed syntax validation."

if [ "$sync_ok" = "1" ]; then
    log "Sync completed."
fi

exec sh "$TARGET" "$@"
