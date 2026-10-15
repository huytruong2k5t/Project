#!/usr/bin/env bash
# Source this helper from a runner. No recursive glob: candidate module names overlap.
_rtl_project="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
declare -A _rtl_paths=()
while IFS=$'\t' read -r old new; do
    _rtl_paths["$old"]="$new"
done < "$_rtl_project/scripts/rtl_paths.tsv"
rtl_path() {
    local key="rtl/${1%.sv}.sv"
    [[ -n "${_rtl_paths[$key]:-}" ]] || { echo "Unknown RTL: $1" >&2; return 2; }
    printf '%s/%s\n' "$_rtl_project" "${_rtl_paths[$key]}"
}
