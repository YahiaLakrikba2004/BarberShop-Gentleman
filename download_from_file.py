import os
import urllib.request

output_dir = 'assets/images/gallery'
os.makedirs(output_dir, exist_ok=True)

with open('urls.txt', 'r') as f:
    urls = [line.strip() for line in f if line.strip()]

for i, url in enumerate(urls, 1):
    filename = f'real_work{i}.jpg'
    path = os.path.join(output_dir, filename)
    try:
        print(f"Downloading image {i}...")
        with urllib.request.urlopen(url) as response, open(path, 'wb') as out_file:
            out_file.write(response.read())
        print(f"Saved to {path}")
    except Exception as e:
        print(f"Error downloading {url}: {e}")
