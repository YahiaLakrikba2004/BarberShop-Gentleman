import shutil
import os

source_dir = r"C:\Users\lakri\Desktop"
target_dir = r"c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\images\gallery"

files_map = {
    "559369300_18059933282453525_1390866222774554323_n..jpg": "gallery_user_1.jpg",
    "568191015_18051660764649505_6742582659389823600_n..jpg": "gallery_user_2.jpg",
    "568826707_18026890292734034_4452958032942761751_n..jpg": "gallery_user_3.jpg",
    "569768428_18084831305058443_584600004985830437_n..jpg": "gallery_user_4.jpg",
    "570357856_18070385330029675_8043649317022584049_n..jpg": "gallery_user_5.jpg",
    "579728175_18170565385374025_2788789791144170794_n..jpg": "gallery_user_6.jpg",
    "581708172_18244835692290888_4696405989649926804_n..jpg": "gallery_user_7.jpg"
}

if not os.path.exists(target_dir):
    os.makedirs(target_dir)

print(f"Target directory: {target_dir}")

for src_name, dst_name in files_map.items():
    src_path = os.path.join(source_dir, src_name)
    dst_path = os.path.join(target_dir, dst_name)
    
    try:
        if os.path.exists(src_path):
            shutil.copy2(src_path, dst_path)
            print(f"Copied {src_name} to {dst_name}")
        else:
            print(f"Source file not found: {src_path}")
    except Exception as e:
        print(f"Error copying {src_name}: {e}")

print("Copy operation completed.")
