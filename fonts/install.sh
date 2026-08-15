#!/usr/bin/env bash
# Install the dotfiles font set into the current user's font directory.
# This script requires --yes when called non-interactively. bootstrap.sh only
# passes --yes after the user explicitly selected the fonts option.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MANIFEST="$SCRIPT_DIR/sources.txt"

if [ "${1:-}" != "--yes" ]; then
    if [ ! -t 0 ]; then
        echo "Refusing to install fonts without explicit consent. Re-run with --yes." >&2
        exit 1
    fi

    read -r -p "Install Fira Code, IBM Plex Mono, and Source Code Pro for this user? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "Font installation cancelled."; exit 0 ;;
    esac
fi

case "$(uname -s)" in
    Linux)  FONT_DIR="$HOME/.local/share/fonts" ;;
    Darwin) FONT_DIR="$HOME/Library/Fonts" ;;
    *)
        echo "Unsupported platform for install.sh: $(uname -s)" >&2
        echo "On Windows, run: powershell -ExecutionPolicy Bypass -File fonts/install.ps1" >&2
        exit 1
        ;;
esac

if [ ! -f "$MANIFEST" ]; then
    echo "Font manifest not found: $MANIFEST" >&2
    exit 1
fi

for command_name in curl unzip find; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
done

mkdir -p "$FONT_DIR"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

while IFS='|' read -r family url; do
    [ -n "$family" ] || continue
    case "$family" in
        \#*) continue ;;
    esac

    archive="$TEMP_DIR/${family// /-}.zip"
    extract_dir="$TEMP_DIR/${family// /-}"

    echo "Downloading $family..."
    curl --fail --location --retry 3 --silent --show-error "$url" --output "$archive"
    mkdir -p "$extract_dir"
    unzip -q "$archive" -d "$extract_dir"

    found=false
    while IFS= read -r font_file; do
        found=true
        cp -f "$font_file" "$FONT_DIR/"
    done < <(find "$extract_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print)

    if [ "$found" = false ]; then
        echo "No TTF or OTF files found in the $family download." >&2
        exit 1
    fi
done < "$MANIFEST"

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR"
fi

echo "Installed fonts into $FONT_DIR"
echo "Restart applications that were open before the installation."
