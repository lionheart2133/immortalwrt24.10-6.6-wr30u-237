#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/.." && pwd)"
source_dir="${1:-}"

if [[ -z "$source_dir" || ! -f "$source_dir/defconfig/mt7981-ax3000.config" ]]; then
  echo "Usage: $0 /path/to/immortalwrt-mt798x-rebase-25.12" >&2
  exit 2
fi

perl "$source_dir/scripts/kconfig.pl" + \
  "$source_dir/defconfig/mt7981-ax3000.config" \
  "$repo_dir/config/custom.config" > "$source_dir/.config"

bash "$repo_dir/diy-part1.sh" "$source_dir"
bash "$repo_dir/diy-part2.sh" "$source_dir"
cp "$source_dir/.config" "$repo_dir/.config"

echo "Updated $repo_dir/.config"
sha256sum "$repo_dir/.config"
