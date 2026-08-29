#!/usr/bin/env bash
# Install the dotfiles font set into the current user's font directory.
#
# Usage:
#   fonts/install.sh                              interactive family selector
#   fonts/install.sh --yes                        install every family, no prompts (used by bootstrap.sh)
#   fonts/install.sh --only "Fira Code,Iosevka"   install only the named families
#
# --only takes a comma-separated list of family names from sources.txt
# (case-insensitive) and counts as explicit consent on its own.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MANIFEST="$SCRIPT_DIR/sources.txt"

usage() {
    cat <<USAGE
Usage: $(basename "${BASH_SOURCE[0]}") [--yes] [--only "Family,Family"]

  (no flags)      Show an interactive selector and install the chosen families.
  --yes           Install every family without prompting (used by bootstrap.sh).
  --only "A,B"    Install only the named families (comma-separated,
                  case-insensitive). Counts as explicit consent.
  --help          Show this help.
USAGE
}

ASSUME_YES=false
ONLY=""

while [ $# -gt 0 ]; do
    case "$1" in
        --yes) ASSUME_YES=true ;;
        --only)
            if [ $# -lt 2 ]; then
                echo "--only requires a comma-separated family list" >&2
                exit 1
            fi
            ONLY="$2"
            shift
            ;;
        --only=*) ONLY="${1#--only=}" ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
    shift
done

if [ ! -f "$MANIFEST" ]; then
    echo "Font manifest not found: $MANIFEST" >&2
    exit 1
fi

FAMILIES=()
while IFS='|' read -r family _rest; do
    [ -n "$family" ] || continue
    case "$family" in
        \#*) continue ;;
    esac
    FAMILIES+=("$family")
done < "$MANIFEST"

if [ "${#FAMILIES[@]}" -eq 0 ]; then
    echo "No font entries found in the manifest: $MANIFEST" >&2
    exit 1
fi

# Interactive family selector. Skipped when --yes or --only was given, both of
# which represent explicit consent.
if [ "$ASSUME_YES" = false ] && [ -z "$ONLY" ]; then
    if [ ! -t 0 ]; then
        echo "Refusing to install fonts without explicit consent." >&2
        echo "Re-run with --yes (everything) or --only \"Family,Family\"." >&2
        exit 1
    fi

    echo "Available fonts:"
    i=1
    for family in "${FAMILIES[@]}"; do
        echo "  $i) $family"
        i=$((i + 1))
    done
    echo ""
    read -r -p "Choose numbers or names separated by commas/spaces, or 'all' [all]: " selection
    selection="$(printf '%s' "$selection" | tr '[:upper:]' '[:lower:]' | tr ',' ' ')"

    if [ -z "$selection" ]; then
        selection="all"
    fi

    add_pick() {
        case ",$ONLY," in
            *",$1,"*) ;;
            *) ONLY="${ONLY:+$ONLY,}$1" ;;
        esac
    }

    for item in $selection; do
        case "$item" in
            all)
                ONLY=""
                break
                ;;
            *[!0-9]*)
                match=""
                for family in "${FAMILIES[@]}"; do
                    fam_lower="$(printf '%s' "$family" | tr '[:upper:]' '[:lower:]')"
                    if [ "$fam_lower" = "$item" ]; then
                        match="$family"
                    fi
                done
                if [ -z "$match" ]; then
                    echo "Unknown font: $item" >&2
                    exit 1
                fi
                add_pick "$match"
                ;;
            *)
                if [ "$item" -lt 1 ] || [ "$item" -gt "${#FAMILIES[@]}" ]; then
                    echo "Unknown selection: $item" >&2
                    exit 1
                fi
                add_pick "${FAMILIES[$((item - 1))]}"
                ;;
        esac
    done
fi

ONLY_LOWER="$(printf '%s' "$ONLY" | tr '[:upper:]' '[:lower:]')"

want_family() {
    if [ -z "$ONLY_LOWER" ]; then
        return 0
    fi
    local fam_lower
    fam_lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case ",$ONLY_LOWER," in
        *",$fam_lower,"*) return 0 ;;
    esac
    return 1
}

# Validate every requested family exists before downloading anything.
if [ -n "$ONLY_LOWER" ]; then
    IFS=',' read -r -a REQUESTED <<< "$ONLY_LOWER"
    for name in "${REQUESTED[@]}"; do
        [ -n "$name" ] || continue
        found=false
        for family in "${FAMILIES[@]}"; do
            fam_lower="$(printf '%s' "$family" | tr '[:upper:]' '[:lower:]')"
            if [ "$fam_lower" = "$name" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            echo "Requested font not found in the manifest: $name" >&2
            exit 1
        fi
    done
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

for command_name in curl unzip find; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
done

mkdir -p "$FONT_DIR"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

while IFS='|' read -r family url filter; do
    [ -n "$family" ] || continue
    case "$family" in
        \#*) continue ;;
    esac

    if ! want_family "$family"; then
        echo "Skipping $family (not selected)."
        continue
    fi

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
    done < <(find "$extract_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' \) ${filter:+-ipath "*${filter}*"} -print)

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
