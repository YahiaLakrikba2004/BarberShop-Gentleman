
import os
import shutil

src = r"C:\Users\lakri\Desktop\Piove fuori, ma una buona rasatura è sempre il miglior antidoto!.mp4"
dst_dir = r"c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\video"
dst = os.path.join(dst_dir, "rain_shave_video.mp4")

if not os.path.exists(dst_dir):
    os.makedirs(dst_dir)
    print(f"Created directory: {dst_dir}")

shutil.copy2(src, dst)
print(f"Copied file to: {dst}")
