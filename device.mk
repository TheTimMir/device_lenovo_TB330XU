#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/lenovo/TB330XU
# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Boot control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.0-impl \
    android.hardware.boot@1.0-service \
    otapreopt_script \
    cppreopts.sh \
    update_engine \
    update_verifier \
    update_engine_sideload \
    adbd.recovery \
    minadbd.recovery \
    snapuserd.ramdisk \
    fastbootd
    
# USB ConfigFS properties
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.usb.config=adb,mtp \
    persist.adb.nonblocking_ffs=1 \
    ro.adb.secure=0 \
    ro.recovery.usb.vid=18D1 \
    ro.recovery.usb.adb.pid=D001 \
    ro.recovery.usb.fastboot.pid=4EE0

# Stock first-stage ramdisk required for normal Android boot when
# recovery is stored in boot.img.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/first_stage_ramdisk/fstab.mt6768:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt6768 \
    $(LOCAL_PATH)/prebuilt/first_stage_ramdisk/fstab.mt8786:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt8786 \
    $(LOCAL_PATH)/prebuilt/first_stage_ramdisk/fstab.mt8786dm:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt8786dm 
    