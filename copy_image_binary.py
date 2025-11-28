import os

source_path = r"C:\Users\lakri\.gemini\antigravity\brain\32659ba6-94bc-4401-a167-d648675c17eb\gentleman_gold_logo_1764288441819.png"
dest_path = r"c:\Users\lakri\Desktop\BarberShop-Gentleman\assets\images\gentleman_logo.png"

try:
    with open(source_path, 'rb') as f_src:
        content = f_src.read()
        with open(dest_path, 'wb') as f_dest:
            f_dest.write(content)
    print(f"Successfully copied {len(content)} bytes.")
except Exception as e:
    print(f"Error: {e}")
