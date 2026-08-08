#!/usr/bin/env bash
set -euo pipefail

source_dir="${1:-.}"
config_generate="$source_dir/package/base-files/files/bin/config_generate"

if grep -q 'ipad=${ipaddr:-"192.168.2.1"}' "$config_generate"; then
  echo "Default LAN address is already 192.168.2.1"
elif grep -q 'ipad=${ipaddr:-"192.168.6.1"}' "$config_generate"; then
  sed -i 's/ipad=${ipaddr:-"192\.168\.6\.1"}/ipad=${ipaddr:-"192.168.2.1"}/' "$config_generate"
  echo "Changed default LAN address to 192.168.2.1"
else
  echo "Unable to locate the upstream default LAN address in $config_generate" >&2
  exit 1
fi
