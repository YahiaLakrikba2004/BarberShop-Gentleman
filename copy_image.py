import shutil
import os

source = r"C:\Users\lakri\.gemini\antigravity\brain\32659ba6-94bc-4401-a167-d648675c17eb\gentleman_gold_logo_1764288441819.png"
destination = r"c:\Users\lakri\Desktop\BarberShop-Gentleman\assets\images\gentleman_logo.png"

try:
    shutil.copy2(source, destination)
    print(f"Successfully copied to {destination}")
except Exception as e:
    print(f"Error copying file: {e}")
