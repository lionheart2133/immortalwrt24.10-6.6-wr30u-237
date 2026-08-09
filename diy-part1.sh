#!/usr/bin/env bash
set -euo pipefail

source_dir="${1:-.}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_generate="$source_dir/package/base-files/files/bin/config_generate"
layout_patch="$script_dir/patches/100-wr30u-112m-nmbm.patch"

if grep -q '^define Device/xiaomi_mi-router-wr30u-112m-nmbm$' \
  "$source_dir/target/linux/mediatek/image/filogic.mk" && \
  [[ -f "$source_dir/target/linux/mediatek/dts/mt7981b-xiaomi-mi-router-wr30u-112m-nmbm.dts" ]] && \
  grep -q 'xiaomi,mi-router-wr30u-112m-nmbm' \
    "$source_dir/package/boot/uboot-tools/uboot-envtools/files/mediatek_filogic" && \
  grep -q 'xiaomi,mi-router-wr30u-112m-nmbm' \
    "$source_dir/target/linux/mediatek/filogic/base-files/etc/board.d/01_leds" && \
  [[ "$(grep -c 'xiaomi,mi-router-wr30u-112m-nmbm' \
    "$source_dir/target/linux/mediatek/filogic/base-files/etc/board.d/02_network")" -eq 2 ]]; then
  echo "WR30U 112M NMBM target is already present"
else
  patch -d "$source_dir" -p1 --forward --fuzz=0 < "$layout_patch"
  echo "Added WR30U 112M NMBM target"
fi

if grep -q 'ipad=${ipaddr:-"192.168.2.1"}' "$config_generate"; then
  echo "Default LAN address is already 192.168.2.1"
elif grep -Eq 'ipad=\$\{ipaddr:-"192\.168\.(1|6)\.1"\}' "$config_generate"; then
  sed -Ei 's/ipad=\$\{ipaddr:-"192\.168\.(1|6)\.1"\}/ipad=${ipaddr:-"192.168.2.1"}/' "$config_generate"
  echo "Changed default LAN address to 192.168.2.1"
else
  echo "Unable to locate the upstream default LAN address in $config_generate" >&2
  exit 1
fi
