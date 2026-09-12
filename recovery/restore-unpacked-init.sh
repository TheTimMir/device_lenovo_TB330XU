#!/bin/sh

set -eu

ramdisk_root="$1"
upx_tool="vendor/recovery/tools/upx"
init_binary="$ramdisk_root/system/bin/init"

[ -x "$upx_tool" ] || {
    echo "error: UPX not found: $upx_tool" >&2
    exit 1
}

[ -f "$init_binary" ] || {
    echo "error: init not found: $init_binary" >&2
    exit 1
}

if "$upx_tool" -q -t "$init_binary" >/dev/null 2>&1; then
    "$upx_tool" -q -d "$init_binary"
fi
