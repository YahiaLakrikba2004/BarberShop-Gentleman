import 'dart:io';

void main() async {
  final file = File('assets/images/gallery/real_work1.jpg');
  if (await file.exists()) {
    final bytes = await file.openRead(0, 10).first;
    print('First bytes: $bytes');
    // JPEG magic number is FF D8
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      print('Valid JPEG header found.');
    } else {
      print('INVALID header. Content might be text/html.');
      final text = String.fromCharCodes(bytes);
      print('Preview: $text');
    }
  } else {
    print('File not found');
  }
}
