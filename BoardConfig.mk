#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/lenovo/TB330XU

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    system \
    vendor

BOARD_USES_RECOVERY_AS_BOOT := true
TW_NO_FASTBOOT_BOOT := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 := 
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a75

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# APEX
OVERRIDE_TARGET_FLATTEN_APEX := true

# Bootloader
# Confirmed by the stock vendor build properties and scatter package.
TARGET_BOOTLOADER_BOARD_NAME := barley_row_lte
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_DENSITY := 240
# Confirmed by the stock DTBO's mediatek,lcd-backlight node.
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
# The LED class exposes a 0..255 control even though the MTK PWM driver maps
# that range internally to its 12-bit (0..4095) hardware level.
TW_MAX_BRIGHTNESS := 255
# OrangeFox themes are generated for a logical width of 1080.  Preserve the
# panel's native 1200x1920 (16:10) aspect ratio: 1920 * 1080 / 1200 = 1728.
OF_SCREEN_H := 1728

# Kernel
BOARD_BOOT_HEADER_VERSION := 2
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 buildvariant=user
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x07c80000
BOARD_KERNEL_TAGS_OFFSET := 0x0bc80000
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --kernel_offset 0x00080000
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset 0x0bc80000
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_INCLUDE_DTB_IN_BOOTIMG :=

# Kernel - prebuilt
TARGET_FORCE_PREBUILT_KERNEL := true
ifeq ($(TARGET_FORCE_PREBUILT_KERNEL),true)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
endif

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_SUPER_PARTITION_SIZE := 11811160064
BOARD_SUPER_PARTITION_GROUPS := lenovo_dynamic_partitions
BOARD_LENOVO_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    vendor \
    product
# Reported by lpdump on S2000892_240206_ROW (main_a/main_b).
BOARD_LENOVO_DYNAMIC_PARTITIONS_SIZE := 11809062912
BOARD_USE_DYNAMIC_PARTITIONS := true


# Platform
# MT8786 / Helio G88 uses MediaTek's mt6768 platform namespace in stock
TARGET_BOARD_PLATFORM := mt6768

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
# OrangeFox's size-reduction pass uses UPX on large executables. Android init
# also executes itself as the enforcing vendor_init domain, where an UPX stub
# is denied execmem and crashes. Restore only init after that pass and before
# the ramdisk is packed; all other executables remain compressed.
# Expand PRODUCT_OUT when the recovery packaging rule runs, not while this
# BoardConfig is initially parsed.
BOARD_RECOVERY_IMAGE_PREPARE = $(DEVICE_PATH)/recovery/prepare-recovery-ramdisk.sh $(PRODUCT_OUT)/recovery/root
# Stock uses FBE v2 on top of metadata encryption. Without crypto support the
# raw userdata device contains encrypted sectors and cannot be probed.
TW_INCLUDE_CRYPTO := true
TW_USE_FSCRYPT_POLICY := 2
BOARD_USES_METADATA_PARTITION := true

# Match the stock S2000892_240206_ROW patch level.  Keymaster uses this value
# when unwrapping the metadata-encryption key; the usual 2099 anti-rollback
# hack makes the stock 202401 key look stale and prevents /data decryption.
PLATFORM_SECURITY_PATCH := 2024-01-05
VENDOR_SECURITY_PATCH := 2024-01-05

# Verified Boot
# The TB330XU boot chain still expects a valid AVB footer even when vbmeta
# verification is disabled. Add the unsigned boot hash footer during image
# creation instead of requiring a manual post-build avbtool invocation.
BOARD_AVB_ENABLE := true
BOARD_AVB_BOOT_ADD_HASH_FOOTER_ARGS += --algorithm NONE

PLATFORM_VERSION := 16.1.0

# TWRP Configuration
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES :=
TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
# This touchscreen reports finger state through EV_KEY/BTN_TOUCH
# Without this drag coordinates work but finger-up never reaches the GUI
TW_USE_KEY_CODE_TOUCH_SYNC := 330
TW_USE_TOOLBOX := true
TW_INCLUDE_REPACKTOOLS := true
# The generic recovery init already provides ConfigFS/FunctionFS handling
# Do not also install TWRP's legacy android_usb sysfs rules
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_NO_HAPTICS := true
OF_FLASHLIGHT_ENABLE := 0
OF_NO_GREEN_LED := 1