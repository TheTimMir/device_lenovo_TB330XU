#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#
export OF_MAINTAINER="TheTimMir"
export FOX_MAINTAINER_PATCH_VERSION="1"

export FOX_BUILD_DEVICE=TB330XU
export FOX_AB_DEVICE=1
export FOX_VIRTUAL_AB_DEVICE=1
export OF_NO_REFLASH_CURRENT_ORANGEFOX=1
export FOX_VANILLA_BUILD=1
export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
export OF_FORCE_PREBUILT_KERNEL=1
export FOX_EXCLUDE_NANO_EDITOR=1
export FOX_USE_DATE_BINARY=1

# OrangeFox's health-service battery reader is unreliable on this MTK device.
# The legacy reader uses the working battery capacity/status sysfs nodes.
export OF_USE_LEGACY_BATTERY_SERVICES=1
export OF_DEFAULT_KEYMASTER_VERSION=4.1

# LZMA/XZ/LZ4 ramdisks cannot boot: the stock kernel only enables RD_GZIP.
# Compress recovery executables instead, preserving Bash, ZIP, MTP, exFAT, and
# the rest of the normal feature set. Keep this as the final export.
export FOX_COMPRESS_EXECUTABLES=1
