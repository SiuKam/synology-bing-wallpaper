#!/bin/sh
set -eu

PROGRAM_NAME="synology-bing-wallpaper"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

: "${SAVE_DIR:=/volume1/download/wallpaper}"
: "${BING_MARKET:=zh-CN}"
: "${BING_HOST:=cn.bing.com}"
: "${UHD_WIDTH:=3840}"
: "${UHD_HEIGHT:=2160}"
: "${INSECURE_TLS:=0}"
: "${UPDATE_LOGIN:=1}"
: "${UPDATE_DESKTOP:=1}"
: "${WALLPAPER_CONFIG:=$PROJECT_DIR/config/config.sh}"

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

if [ -f "$WALLPAPER_CONFIG" ]; then
    # shellcheck disable=SC1090
    . "$WALLPAPER_CONFIG"
fi

: "${SAVE_DIR:=/volume1/download/wallpaper}"
: "${BING_MARKET:=zh-CN}"
: "${BING_HOST:=cn.bing.com}"
: "${UHD_WIDTH:=3840}"
: "${UHD_HEIGHT:=2160}"
: "${INSECURE_TLS:=0}"
: "${UPDATE_LOGIN:=1}"
: "${UPDATE_DESKTOP:=1}"

[ "$(id -u)" -eq 0 ] || fail "Please run as root so DSM system files can be updated."
command_exists sed || fail "sed is required."
command_exists grep || fail "grep is required."
command_exists mktemp || fail "mktemp is required."

mkdir -p "$SAVE_DIR"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/${PROGRAM_NAME}.XXXXXX")
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM HUP

fetch() {
    url=$1
    output=$2

    if command_exists curl; then
        if [ "$INSECURE_TLS" = "1" ]; then
            curl -kfsSL --retry 5 --connect-timeout 15 --max-time 60 -o "$output" "$url"
        else
            curl -fsSL --retry 5 --connect-timeout 15 --max-time 60 -o "$output" "$url"
        fi
    elif command_exists wget; then
        if [ "$INSECURE_TLS" = "1" ]; then
            wget -t 5 -T 60 --no-check-certificate -qO "$output" "$url"
        else
            wget -t 5 -T 60 -qO "$output" "$url"
        fi
    else
        fail "curl or wget is required."
    fi
}

json_string() {
    key=$1
    file=$2
    sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$file" | head -n 1
}

API_URL="https://${BING_HOST}/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${BING_MARKET}&uhd=1&uhdwidth=${UHD_WIDTH}&uhdheight=${UHD_HEIGHT}"
INFO_FILE="$TMP_DIR/bing.json"
IMAGE_FILE="$TMP_DIR/wallpaper.jpg"

log "Fetching Bing metadata (market: $BING_MARKET)..."
fetch "$API_URL" "$INFO_FILE"

relative_url=$(json_string url "$INFO_FILE")
end_date=$(json_string enddate "$INFO_FILE")
title=$(json_string title "$INFO_FILE")
copyright=$(json_string copyright "$INFO_FILE")

[ -n "$relative_url" ] || fail "Bing response did not contain an image URL."
[ -n "$end_date" ] || end_date=$(date '+%Y%m%d')

case "$relative_url" in
    http://*|https://*) image_url=$relative_url ;;
    *) image_url="https://${BING_HOST}${relative_url}" ;;
esac

save_file="$SAVE_DIR/${end_date}_bing.jpg"

log "Downloading wallpaper..."
fetch "$image_url" "$IMAGE_FILE"
[ -s "$IMAGE_FILE" ] || fail "Downloaded wallpaper is empty."

mv -f "$IMAGE_FILE" "$save_file"
chmod 0644 "$save_file" 2>/dev/null || true
log "Saved: $save_file"

set_synoinfo() {
    key=$1
    value=$2
    file=/etc/synoinfo.conf
    escaped=$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')

    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=\"${escaped}\"|" "$file"
    else
        printf '%s="%s"\n' "$key" "$value" >> "$file"
    fi
}

if [ "$UPDATE_LOGIN" = "1" ]; then
    if [ -f /etc/synoinfo.conf ] && [ -d /usr/syno/etc ]; then
        rm -f /usr/syno/etc/login_background*.jpg
        cp -f "$save_file" /usr/syno/etc/login_background.jpg
        cp -f "$save_file" /usr/syno/etc/login_background_hd.jpg

        set_synoinfo login_background_customize yes
        [ -n "$title" ] && set_synoinfo login_welcome_title "$title"
        [ -n "$copyright" ] && set_synoinfo login_welcome_msg "$copyright"
        log "DSM login wallpaper updated."
    else
        warn "DSM login paths were not found; skipped login wallpaper update."
    fi
fi

if [ "$UPDATE_DESKTOP" = "1" ]; then
    desktop_2x=/usr/syno/synoman/webman/resources/images/2x/default_wallpaper/dsm7_01.jpg
    desktop_1x=/usr/syno/synoman/webman/resources/images/1x/default_wallpaper/dsm7_01.jpg

    if [ -d "$(dirname "$desktop_2x")" ] && [ -d "$(dirname "$desktop_1x")" ]; then
        cp -f "$save_file" "$desktop_2x"
        ln -sf "$desktop_2x" "$desktop_1x"
        log "DSM desktop default wallpaper updated."
    else
        warn "DSM desktop wallpaper paths were not found; skipped desktop update."
    fi
fi

log "Done. ${title:-Bing daily wallpaper}"
