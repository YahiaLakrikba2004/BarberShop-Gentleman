
import os

desktop = r"C:\Users\lakri\Desktop"
output_file = "debug_output.txt"

with open(output_file, "w", encoding="utf-8") as f:
    f.write(f"Listing files in {desktop}:\n")
    try:
        files = os.listdir(desktop)
        for name in files:
            if "mp4" in name.lower() or "piove" in name.lower():
                f.write(f"{name}\n")
    except Exception as e:
        f.write(f"Error listing desktop: {e}\n")

print("Debug listing complete.")
