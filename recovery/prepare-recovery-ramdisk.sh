#!/bin/sh

set -eu

ramdisk_root="$1"
upx_tool="vendor/recovery/tools/upx"
init_binary="$ramdisk_root/system/bin/init"
languages_dir="$ramdisk_root/twres/languages"

# OrangeFox compresses large binaries with UPX. Android init runs as
# vendor_init, where the UPX stub cannot use executable writable memory,
# so restore the original init binary before packaging the ramdisk.
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

# boot is limited to 32 MiB on TB330XU. Keep only the languages useful for
# this build so that there is enough headroom for Magisk to patch boot.
if [ -d "$languages_dir" ]; then
    find "$languages_dir" -type f \
        ! -name 'en.xml' \
        ! -name 'ca_ES.xml' \
        ! -name 'ru.xml' \
        -delete
fi