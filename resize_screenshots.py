import glob
from PIL import Image

def process_screenshots():
    out_dir = "ios_screenshots"
    import os
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    target_width = 1242
    target_height = 2688
    
    images = glob.glob('flutter_*.png')
    if not images:
        print("No flutter_*.png files found")
        return
        
    print(f"Found {len(images)} images.")
    for path in images[:10]: # Process up to 10 screenshots
        with Image.open(path) as img:
            print(f"Processing {path}, size: {img.size}")
            
            # Create a new image with the target dimensions, let's say with a white or custom color background.
            # We can also scale the original image properly to fit.
            new_img = Image.new("RGB", (target_width, target_height), (0, 0, 0)) # black background or maybe blur
            
            # Calculate aspect ratio preserving resize
            img_ratio = img.width / img.height
            target_ratio = target_width / target_height
            
            if img_ratio > target_ratio:
                # image is wider
                new_w = target_width
                new_h = int(new_w / img_ratio)
            else:
                # image is taller
                new_h = target_height
                new_w = int(new_h * img_ratio)
                
            resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Center the image
            offset_x = (target_width - new_w) // 2
            offset_y = (target_height - new_h) // 2
            
            new_img.paste(resized, (offset_x, offset_y))
            
            out_path = os.path.join(out_dir, path)
            new_img.save(out_path)
            print(f"Saved {out_path}")

if __name__ == '__main__':
    process_screenshots()
