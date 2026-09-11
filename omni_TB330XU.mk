#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)

# Inherit from TB330XU device
$(call inherit-product, device/lenovo/TB330XU/device.mk)

PRODUCT_DEVICE := TB330XU
PRODUCT_NAME := omni_TB330XU
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB330XU
PRODUCT_MANUFACTURER := lenovo

PRODUCT_GMS_CLIENTID_BASE := android-lenovo

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="TB330XU-user 13 TQ1A.230105.002 S2000892_240206_ROW release-keys"

BUILD_FINGERPRINT := Lenovo/TB330XU/TB330XU:13/TQ1A.230105.002/S2000892_240206_ROW:user/release-keys
