#!/usr/bin/env bash
# Install the tracked Pi Coding Agent configuration as real files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
BACKUP_DIR="${PI_CONFIG_BACKUP_DIR:-$HOME/.pi-config-backup/$(date +%Y%m%d-%H%M%S)}"
INSTALL_PACKAGES=true

usage() {
    cat <<USAGE
Usage: ./pi/install.sh [options]

Copies the tracked Pi configuration into:
  $TARGET_DIR

Options:
  --skip-packages  Copy configuration files without running npm ci
  --help           Show this help

Tracked configuration files are copied and never symlinked. npm may create
its normal executable shims under the generated node_modules directory.
Existing symlinked configuration paths are moved to:
  $BACKUP_DIR
USAGE
}

backup_path() {
    local target="$1"
    local relative backup_target

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return
    fi

    relative="${target#$HOME/}"
    if [ "$relative" = "$target" ]; then
        relative="absolute${target}"
    fi

    backup_target="$BACKUP_DIR/$relative"
    mkdir -p "$(dirname "$backup_target")"
    mv "$target" "$backup_target"
    printf 'Backed up %s to %s\n' "$target" "$backup_target"
}

copy_file() {
    local source="$1"
    local destination="$2"

    mkdir -p "$(dirname "$destination")"

    if [ -L "$destination" ] || { [ -e "$destination" ] && [ ! -f "$destination" ]; }; then
        backup_path "$destination"
    fi

    if [ -f "$destination" ] && cmp -s "$source" "$destination"; then
        printf 'Unchanged %s\n' "$destination"
        return
    fi

    # -L dereferences source symlinks so the installed result is a real file.
    cp -fL "$source" "$destination"
    printf 'Copied %s\n' "$destination"
}

copy_directory() {
    local source="$1"
    local destination="$2"

    if [ -L "$destination" ] || { [ -e "$destination" ] && [ ! -d "$destination" ]; }; then
        backup_path "$destination"
    fi

    mkdir -p "$destination"
    # -L dereferences source symlinks so the installed result contains copies.
    cp -R -L "$source/." "$destination/"
    printf 'Copied %s\n' "$destination"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --skip-packages) INSTALL_PACKAGES=false ;;
        --help) usage; exit 0 ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

[ -d "$SCRIPT_DIR/extensions" ] || { printf 'Missing Pi extensions directory: %s\n' "$SCRIPT_DIR/extensions" >&2; exit 1; }
[ -d "$SCRIPT_DIR/themes" ] || { printf 'Missing Pi themes directory: %s\n' "$SCRIPT_DIR/themes" >&2; exit 1; }

# Do not install through a symlinked Pi config root.
if [ -L "$TARGET_DIR" ] || { [ -e "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR" ]; }; then
    backup_path "$TARGET_DIR"
fi
mkdir -p "$TARGET_DIR"

copy_directory "$SCRIPT_DIR/extensions" "$TARGET_DIR/extensions"
copy_directory "$SCRIPT_DIR/themes" "$TARGET_DIR/themes"
copy_file "$SCRIPT_DIR/settings.json" "$TARGET_DIR/settings.json"
copy_file "$SCRIPT_DIR/models-store.json" "$TARGET_DIR/models-store.json"
copy_file "$SCRIPT_DIR/npm/package.json" "$TARGET_DIR/npm/package.json"
copy_file "$SCRIPT_DIR/npm/package-lock.json" "$TARGET_DIR/npm/package-lock.json"
copy_file "$SCRIPT_DIR/npm/.gitignore" "$TARGET_DIR/npm/.gitignore"

if [ "$INSTALL_PACKAGES" = true ]; then
    if command -v npm >/dev/null 2>&1; then
        printf 'Installing Pi packages...\n'
        (
            cd "$TARGET_DIR/npm"
            npm ci --ignore-scripts --no-audit --no-fund
        )
    else
        printf 'npm was not found; skipped Pi package installation.\n' >&2
    fi
fi

printf '\nPi Coding Agent configuration installed in %s\n' "$TARGET_DIR"
