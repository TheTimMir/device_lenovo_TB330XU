#!/usr/bin/env python3
"""
LENOVO TAB M11 LTE (TB330XU) ORANGEFOX RECOVERY REPACKER
Builds slot-specific OrangeFox recovery images (A and B) from:
  1. The compiled OrangeFox vendor_boot.img
  2. Fresh vendor_boot dumps from each slot

Key design decisions:
  - Uses each device-dumped vendor_boot as the base so platform ramdisks,
    fstab.mt6768, and kernel modules remain matched to the installed firmware.
  - Generates TWO output images (one per A/B slot) because the slots have
    different ramdisk contents and AVB metadata.
  - Injects fstab into vendor_ramdisk00 (type 0x1) so normal Android boot
    can find the filesystem table. The bootloader only extracts type 0x1
    ramdisks during normal boot.
"""
import os
import sys
import subprocess
import shutil
import shlex

def modify_rc_file(rc_path):
    print(f"Modifying rc file: {rc_path}")
    with open(rc_path, "r") as f:
        content = f.read()
    modified_content = content.replace("on fs && property:ro.debuggable=0", "on fs")
    with open(rc_path, "w") as f:
        f.write(modified_content)

def strip_avb(fstab_path):
    print(f"Stripping AVB options from: {fstab_path}")
    with open(fstab_path, "r") as f:
        lines = f.readlines()
    
    new_lines = []
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            new_lines.append(line)
            continue
        
        parts = stripped.split()
        if len(parts) >= 5:
            opts = parts[4].split(",")
            new_opts = []
            for opt in opts:
                if opt.startswith("avb") or opt.startswith("avb_keys"):
                    continue
                new_opts.append(opt)
            parts[4] = ",".join(new_opts)
            new_lines.append("\t".join(parts) + "\n")
        else:
            new_lines.append(line)
            
    with open(fstab_path, "w") as f:
        f.writelines(new_lines)

def find_tool(base_dir, parent_dir, filename, critical=True):
    # Try repack_tools subfolder first
    tools_path = os.path.join(base_dir, "repack_tools", filename)
    if os.path.exists(tools_path):
        return tools_path
    # Try parent directory
    parent_path = os.path.join(parent_dir, filename)
    if os.path.exists(parent_path):
        return parent_path
    # Try PATH
    path_lookup = shutil.which(filename)
    if path_lookup:
        return path_lookup
    
    if critical:
        print(f"[ERROR] Required tool/file '{filename}' not found! Please place it in 'repack_tools' or the parent directory.")
        sys.exit(1)
    return None

def build_twrp_cpio(base_dir, parent_dir, magiskboot, compiled_img, stock_cpio_for_binaries):
    """Prepare the TWRP recovery CPIO with all modifications.
    Returns path to the modified TWRP CPIO."""
    
    print("\n[1/5] Decompressing recovery ramdisk from compiled TWRP image...")
    compiled_out_dir = os.path.join(base_dir, "temp_compiled_unpacked")
    os.makedirs(compiled_out_dir, exist_ok=True)
    
    unpack_bootimg_py = find_tool(base_dir, parent_dir, "unpack_bootimg.py")
    subprocess.run([
        sys.executable, 
        unpack_bootimg_py, 
        "--boot_img", compiled_img, 
        "--out", compiled_out_dir
    ], check=True)
    
    compiled_ramdisk_fragment = os.path.join(compiled_out_dir, "vendor_ramdisk01")
    twrp_cpio = os.path.join(base_dir, "temp_twrp.cpio")
    if os.path.exists(twrp_cpio):
        os.remove(twrp_cpio)
        
    subprocess.run([magiskboot, "decompress", compiled_ramdisk_fragment, twrp_cpio], check=True)
    shutil.rmtree(compiled_out_dir)

    # Modify property and configuration files
    print("[2/5] Injecting USB and adb settings in prop.default...")
    prop_path = os.path.join(base_dir, "prop_temp.default")
    if os.path.exists(prop_path):
        os.remove(prop_path)
    subprocess.run([magiskboot, "cpio", twrp_cpio, f"extract prop.default {prop_path}"], check=True)

    with open(prop_path, "r") as f:
        lines = f.readlines()
    
    modified_lines = []
    for line in lines:
        if "persist.sys.usb.config=" in line:
            modified_lines.append("persist.sys.usb.config=mtp,adb\n")
        else:
            modified_lines.append(line)
            
    modified_lines.append("\n# Recovery ConfigFS configurations\n")
    modified_lines.append("ro.recovery.usb.vid=18D1\n")
    modified_lines.append("ro.recovery.usb.adb.pid=D001\n")
    modified_lines.append("ro.recovery.usb.fastboot.pid=4EE0\n")

    with open(prop_path, "w") as f:
        f.writelines(modified_lines)

    subprocess.run([magiskboot, "cpio", twrp_cpio, f"add 644 prop.default {prop_path}"], check=True)
    os.remove(prop_path)

    # Remove conflicting rc
    subprocess.run([magiskboot, "cpio", twrp_cpio, "rm init.recovery.usb.rc"], capture_output=True)

    # Modify MediaTek triggers
    print("[3/5] Modifying MTK recovery service triggers...")
    for rc_file in ["init.recovery.mt6768.rc", "init.recovery.mt8786.rc"]:
        temp_rc_path = os.path.join(base_dir, f"temp_{rc_file}")
        if os.path.exists(temp_rc_path): os.remove(temp_rc_path)
        subprocess.run([magiskboot, "cpio", twrp_cpio, f"extract {rc_file} {temp_rc_path}"], check=True)
        modify_rc_file(temp_rc_path)
        subprocess.run([magiskboot, "cpio", twrp_cpio, f"add 755 {rc_file} {temp_rc_path}"], check=True)
        os.remove(temp_rc_path)

    # Extract stock binaries for dynamic linker matching
    print("[4/5] Injecting stock adbd and minadbd binaries...")
    adbd_temp = os.path.join(base_dir, "adbd_temp")
    minadbd_temp = os.path.join(base_dir, "minadbd_temp")
    subprocess.run([magiskboot, "cpio", stock_cpio_for_binaries, f"extract system/bin/adbd {adbd_temp}"], check=True)
    subprocess.run([magiskboot, "cpio", stock_cpio_for_binaries, f"extract system/bin/minadbd {minadbd_temp}"], check=True)
    subprocess.run([magiskboot, "cpio", twrp_cpio, f"add 755 system/bin/adbd {adbd_temp}"], check=True)
    subprocess.run([magiskboot, "cpio", twrp_cpio, f"add 755 system/bin/minadbd {minadbd_temp}"], check=True)
    os.remove(adbd_temp)
    os.remove(minadbd_temp)

    # Extract stock init.recovery.usb.rc and inject it
    usb_rc_temp = os.path.join(base_dir, "usb_rc_temp")
    res_usb = subprocess.run([magiskboot, "cpio", stock_cpio_for_binaries, f"extract init.recovery.usb.rc {usb_rc_temp}"], capture_output=True)
    if res_usb.returncode == 0:
        print("[USB] Found stock init.recovery.usb.rc, injecting...")
        subprocess.run([magiskboot, "cpio", twrp_cpio, f"add 644 init.recovery.usb.rc {usb_rc_temp}"], check=True)
        os.remove(usb_rc_temp)
    else:
        print("[USB] Stock init.recovery.usb.rc not found, using fallback...")
        fallback_path = find_tool(base_dir, parent_dir, "init.recovery.usb.rc.txt", critical=False)
        if fallback_path:
            subprocess.run([magiskboot, "cpio", twrp_cpio, f"add 644 init.recovery.usb.rc {fallback_path}"], check=True)

    # Inject fstab files into recovery ramdisk for recovery mode
    print("[5/5] Injecting fstab into recovery ramdisk...")
    subprocess.run([magiskboot, "cpio", twrp_cpio, "mkdir 755 first_stage_ramdisk"], capture_output=True)
    for fstab_name in ["first_stage_ramdisk/fstab.mt8786", "first_stage_ramdisk/fstab.mt8786dm",
                        "first_stage_ramdisk/fstab.mt6768"]:
        temp_f = os.path.join(base_dir, "fstab_temp")
        res = subprocess.run([magiskboot, "cpio", stock_cpio_for_binaries, f"extract {fstab_name} {temp_f}"], capture_output=True)
        if res.returncode == 0:
            strip_avb(temp_f)
            subprocess.run([magiskboot, "cpio", twrp_cpio, f"add 644 {fstab_name} {temp_f}"], check=True)
            os.remove(temp_f)
    
    return twrp_cpio


def build_slot_image(slot_name, base_dir, parent_dir, magiskboot, stock_img, twrp_cpio, output_path):
    """Build one slot's vendor_boot image with TWRP recovery injected."""
    
    print(f"\n{'='*60}")
    print(f"  Building image for slot {slot_name.upper()}")
    print(f"  Base: {os.path.basename(stock_img)}")
    print(f"{'='*60}")
    
    unpack_bootimg_py = find_tool(base_dir, parent_dir, "unpack_bootimg.py")
    mkbootimg_py = find_tool(base_dir, parent_dir, "mkbootimg.py")

    # Unpack the base image
    base_unpacked_dir = os.path.join(base_dir, f"temp_base_{slot_name}")
    os.makedirs(base_unpacked_dir, exist_ok=True)
    subprocess.run([
        sys.executable, 
        unpack_bootimg_py, 
        "--boot_img", stock_img, 
        "--out", base_unpacked_dir
    ], check=True)
    
    # Compress TWRP cpio for this slot
    twrp_lz4 = os.path.join(base_dir, f"temp_twrp_{slot_name}.lz4")
    if os.path.exists(twrp_lz4): os.remove(twrp_lz4)
    subprocess.run([magiskboot, "compress=lz4_legacy", twrp_cpio, twrp_lz4], check=True)
    
    # Get mkbootimg args from the base image
    res = subprocess.run([
        sys.executable, 
        unpack_bootimg_py, 
        "--boot_img", stock_img, 
        "--format", "mkbootimg"
    ], capture_output=True, text=True, check=True)
    args_str = res.stdout.strip()
    args_list = shlex.split(args_str)

    rebuilt_args = []
    i = 0
    while i < len(args_list):
        arg = args_list[i]
        if arg in ["--dtb", "--vendor_bootconfig", "--vendor_ramdisk_fragment"]:
            val = args_list[i+1]
            if val.startswith("out/"):
                val = val.replace("out/", base_unpacked_dir + "/")
            # Replace recovery ramdisk with TWRP
            if "vendor_ramdisk01" in val:
                val = twrp_lz4
            rebuilt_args.append(arg)
            rebuilt_args.append(val)
            i += 2
        else:
            rebuilt_args.append(arg)
            rebuilt_args.append(args_list[i+1])
            i += 2

    subprocess.run([sys.executable, mkbootimg_py] + rebuilt_args + ["--vendor_boot", output_path], check=True)

    # Clean up
    shutil.rmtree(base_unpacked_dir)
    os.remove(twrp_lz4)
    
    print(f"  ✓ {slot_name.upper()} image: {output_path}")


def main():
    print("=" * 60)
    print("  LENOVO TAB M11 LTE (TB330XU) ORANGEFOX RECOVERY REPACKER")
    print("  Dual-slot A/B aware build")
    print("=" * 60)
    
    base_dir = os.path.dirname(os.path.realpath(__file__))
    parent_dir = os.path.dirname(base_dir)
    
    # Locate magiskboot
    magiskboot = find_tool(base_dir, parent_dir, "magiskboot")
            
    # Input paths
    compiled_img = input("Path to compiled OrangeFox vendor_boot.img [default: ../../../../out/target/product/TB330XU/vendor_boot.img]: ").strip()
    if not compiled_img:
        compiled_img = os.path.abspath(os.path.join(base_dir, "../../../../out/target/product/TB330XU/vendor_boot.img"))
        
    stock_img_a = input("Path to a fresh TB330XU vendor_boot_a dump: ").strip()
    
    stock_img_b = input("Path to a fresh TB330XU vendor_boot_b dump: ").strip()
            
    output_base = input("Output file base name [default: ../orangefox_tb330xu]: ").strip()
    if not output_base:
        output_base = os.path.join(parent_dir, "orangefox_tb330xu")

    if not os.path.exists(compiled_img):
        print(f"[ERROR] Compiled image not found at '{compiled_img}'!")
        sys.exit(1)
    if not os.path.exists(stock_img_a):
        print(f"[ERROR] Fresh vendor_boot_a dump not found at '{stock_img_a}'!")
        sys.exit(1)
    if not os.path.exists(stock_img_b):
        print(f"[ERROR] Fresh vendor_boot_b dump not found at '{stock_img_b}'!")
        sys.exit(1)

    unpack_bootimg_py = find_tool(base_dir, parent_dir, "unpack_bootimg.py")

    # Step 1: Decompress stock recovery ramdisk (from slot A) to get binaries
    print("\n[PREP] Decompressing stock recovery ramdisk for binary extraction...")
    base_a_dir = os.path.join(base_dir, "temp_base_prep")
    os.makedirs(base_a_dir, exist_ok=True)
    subprocess.run([
        sys.executable,
        unpack_bootimg_py,
        "--boot_img", stock_img_a,
        "--out", base_a_dir
    ], check=True)
    
    stock_cpio = os.path.join(base_dir, "temp_stock.cpio")
    stock_ramdisk01 = os.path.join(base_a_dir, "vendor_ramdisk01")
    subprocess.run([magiskboot, "decompress", stock_ramdisk01, stock_cpio], check=True)
    shutil.rmtree(base_a_dir)

    # Step 2: Build the modified TWRP CPIO (shared between both slots)
    twrp_cpio = build_twrp_cpio(base_dir, parent_dir, magiskboot, compiled_img, stock_cpio)
    os.remove(stock_cpio)

    # Step 3: Build slot-specific images
    output_a = output_base + "_a.img"
    output_b = output_base + "_b.img"
    
    build_slot_image("a", base_dir, parent_dir, magiskboot, stock_img_a, twrp_cpio, output_a)
    build_slot_image("b", base_dir, parent_dir, magiskboot, stock_img_b, twrp_cpio, output_b)

    # Clean up shared temp
    os.remove(twrp_cpio)

    print("\n" + "=" * 60)
    print(" SUCCESS! Dual-slot OrangeFox recovery images are ready:")
    print(f"   Slot A: {output_a}")
    print(f"   Slot B: {output_b}")
    print()
    print(" Flash with:")
    print(f"   fastboot flash vendor_boot_a {os.path.basename(output_a)}")
    print(f"   fastboot flash vendor_boot_b {os.path.basename(output_b)}")
    print("=" * 60)

if __name__ == "__main__":
    main()
