#!/bin/sh

set -eu

ramdisk_root="$1"
upx_tool="vendor/recovery/tools/upx"
init_binary="$ramdisk_root/system/bin/init"

if "$upx_tool" -q -t "$init_binary" >/dev/null 2>&1; then
    "$upx_tool" -q -d "$init_binary"
fi
