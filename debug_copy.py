import shutil
import os

# Define the exact path from user request
src_double_dot = r"C:\Users\lakri\Desktop\559369300_18059933282453525_1390866222774554323_n..jpg"
dst = r"c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\images\gallery\gallery_user_1.jpg"
log_file = "copy_log.txt"

with open(log_file, "w") as f:
    f.write(f"Starting debug copy.\n")
    f.write(f"Checking: {src_double_dot}\n")
    
    if os.path.exists(src_double_dot):
        f.write("Source with '..jpg' exists.\n")
        try:
            shutil.copy2(src_double_dot, dst)
            f.write("Copy success.\n")
        except Exception as e:
            f.write(f"Copy failed: {e}\n")
    else:
        f.write("Source with '..jpg' does NOT exist.\n")
        
        # Try single dot
        src_single_dot = src_double_dot.replace("..jpg", ".jpg")
        f.write(f"Checking: {src_single_dot}\n")
        
        if os.path.exists(src_single_dot):
            f.write("Source with '.jpg' exists.\n")
            try:
                shutil.copy2(src_single_dot, dst)
                f.write("Copy success (single dot).\n")
            except Exception as e:
                f.write(f"Copy failed: {e}\n")
        else:
             f.write("Source with '.jpg' also does NOT exist.\n")
             
             # List directory to see what's there
             desktop = r"C:\Users\lakri\Desktop"
             f.write(f"Listing {desktop} (first 20 files):\n")
             try:
                 files = os.listdir(desktop)
                 for file in files[:20]:
                     f.write(f" - {file}\n")
             except Exception as e:
                 f.write(f"Could not list directory: {e}\n")

print("Debug script finished.")
