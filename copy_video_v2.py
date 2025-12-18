
import os
import shutil
import sys

src = r"C:\Users\lakri\Desktop\Piove fuori, ma una buona rasatura è sempre il miglior antidoto!.mp4"
dst_dir = r"c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\video"
dst = os.path.join(dst_dir, "rain_shave_video.mp4")

print(f"Starting copy from {src} to {dst}")

try:
    if not os.path.exists(dst_dir):
        os.makedirs(dst_dir)
        print(f"Created directory: {dst_dir}")
    
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f"Successfully copied file to: {dst}")
    else:
        print(f"Error: Source file not found at {src}")
        # Try to list desktop to debug (if possible via python)
        desktop = r"C:\Users\lakri\Desktop"
        print(f"Listing {desktop}:")
        for f in os.listdir(desktop):
            if "Piove" in f:
                print(f"Found candidate: {f}")
except Exception as e:
    print(f"Exception occurred: {e}")
    sys.exit(1)
