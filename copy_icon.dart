import 'dart:io';

void main() async {
  var src = File(r"C:\Users\lakri\.gemini\antigravity\brain\d50b5033-b50d-4388-a0be-f177b284119c\icon_premium_option_2_gentleman_monogram_1766769902010.png");
  var dst = File(r"c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\images\icon_premium_v2.png");
  
  print("Checking source: ${src.path}");
  if (!src.existsSync()) {
    print("Error: Source not found!");
    exit(1);
  }
  
  try {
    print("Copying...");
    await src.copy(dst.path);
    print("Success: Copied to ${dst.path}");
    if (dst.existsSync()) {
        print("Verified: Destination exists.");
        print("Size: ${dst.lengthSync()} bytes");
    }
  } catch (e) {
    print("Error: $e");
    exit(1);
  }
}
