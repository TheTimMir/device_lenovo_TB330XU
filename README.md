# OrangeFox for Lenovo TB330XU

OrangeFox R12 device tree for the Lenovo Tab M11 (TB330XU), based on stock
`V14.218_T_ZUI_15.1.116` (Android 13, kernel `4.19.191-g5cd34db2898d`).

### Device notes
- A/B device
- Virtual A/B
- Dynamic partitions
- Recovery-as-boot
- MediaTek MT8786
- Stock Keymaster 4.1 (MicroTrust / Beanpod)

## Status

| Feature                           | Status | Notes |
| --------------------------------- | ------ | ----- |
| Boot / display                    | Full   | |
| Touchscreen                       | Full   | |
| Time and CPU temperature          | Full   | |
| Battery                           | Full   | |
| Charging                          | Full   | |
| ADB                               | Full   | |
| MTP                               | Full   | |    
| Fastbootd                         | Full   | |
| Brightness                        | Full   | |
| Internal storage / FBE decryption | Full   | MicroTrust/Beanpod Keymaster 4.1 |
| UI scaling / theme                | Full   | |
| Normal Android boot               | Full   | Recovery-as-boot; normal boot and recovery both supported |
| ZIP flashing                      | Full   | See known quirk below |
| Vibration                         | N/A    | Device has no vibration motor |
| Flashlight                        | N/A    | Device has no flashlight |

## Known quirks

- Keep **"Unmount Vendor before installing ZIP"** disabled. The stock MicroTrust TEE,
  Keymaster and Gatekeeper services are executed from the vendor partition and keep it in use
  while recovery is running.

## Building

```bash
# sync OrangeFox 12.1
...

# clone the device tree
git clone ... device/lenovo/TB330XU

source build/envsetup.sh
lunch omni_TB330XU-eng
mka bootimage
```

## Sources and references

[`nazzar4ik/tb330xu-unpacked-hovatek-twrp`](git://github.com/nazzar4ik/tb330xu-unpacked-hovatek-twrp.git)
[`t0mc1k/TB330FU-TWRP`](git://github.com/t0mc1k/TB330FU-TWRP.git)

## AI assistance

OpenAI Codex was used as a development assistant. 
All device-specific changes were reviewed and tested on-device.