#!/usr/bin/env bash
set -euo pipefail

source_dir="${1:-.}"
cd "$source_dir"

make defconfig
grep -qx 'CONFIG_TARGET_mediatek_filogic_DEVICE_xiaomi_mi-router-wr30u-112m-nmbm=y' .config
grep -qx 'CONFIG_PACKAGE_luci-app-homeproxy=y' .config
grep -qx 'CONFIG_PACKAGE_sing-box=y' .config
grep -qx 'CONFIG_PACKAGE_drill=y' .config
grep -qx 'CONFIG_PACKAGE_mtr-nojson=y' .config
grep -qx 'CONFIG_PACKAGE_iperf3=y' .config

if grep -qE '^CONFIG_PACKAGE_(luci-app-upnp|miniupnpd)=y$' .config; then
  echo "Unexpected UPnP package found in 25.12 test configuration" >&2
  exit 1
fi

if grep -q '^CONFIG_PACKAGE_.*leigod.*=y$' .config; then
  echo "Unexpected Leigod package found in .config" >&2
  exit 1
fi

echo "Configuration validated: WR30U 112M NMBM + HomeProxy + diagnostics, without UPnP"
