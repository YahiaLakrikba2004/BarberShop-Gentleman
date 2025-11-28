import 'dart:io';

void main() async {
  final sourcePath = r'C:\Users\lakri\.gemini\antigravity\brain\32659ba6-94bc-4401-a167-d648675c17eb\gentleman_gold_logo_1764288441819.png';
  final destPath = r'c:\Users\lakri\Desktop\BarberShop-Gentleman\assets\images\gentleman_logo.png';
  
  final source = File(sourcePath);
  final dest = File(destPath);
  
  print('Source exists: ${await source.exists()}');
  
  try {
    final bytes = await source.readAsBytes();
    await dest.writeAsBytes(bytes);
    print('Successfully copied ${bytes.length} bytes to $destPath');
  } catch (e) {
    print('Error copying file: $e');
  }
}
