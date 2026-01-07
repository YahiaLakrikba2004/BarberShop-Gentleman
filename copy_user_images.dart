import 'dart:io';

Future<void> main() async {
  final Map<String, String> files = {
    r"C:\Users\lakri\Desktop\559369300_18059933282453525_1390866222774554323_n..jpg": "gallery_user_1.jpg",
    r"C:\Users\lakri\Desktop\568191015_18051660764649505_6742582659389823600_n..jpg": "gallery_user_2.jpg",
    r"C:\Users\lakri\Desktop\568826707_18026890292734034_4452958032942761751_n..jpg": "gallery_user_3.jpg",
    r"C:\Users\lakri\Desktop\569768428_18084831305058443_584600004985830437_n..jpg": "gallery_user_4.jpg",
    r"C:\Users\lakri\Desktop\570357856_18070385330029675_8043649317022584049_n..jpg": "gallery_user_5.jpg",
    r"C:\Users\lakri\Desktop\579728175_18170565385374025_2788789791144170794_n..jpg": "gallery_user_6.jpg",
    r"C:\Users\lakri\Desktop\581708172_18244835692290888_4696405989649926804_n..jpg": "gallery_user_7.jpg",
  };

  final destDir = Directory(r'c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\images\gallery');
  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }

  for (final entry in files.entries) {
    final srcPath = entry.key;
    final destPath = '${destDir.path}\\${entry.value}';
    final srcFile = File(srcPath);

    if (await srcFile.exists()) {
      try {
        await srcFile.copy(destPath);
        print('Copied to $destPath');
      } catch (e) {
        print('Error copying $srcPath: $e');
      }
    } else {
      print('Source not found: $srcPath');
      // Try single dot
      final srcSingle = srcPath.replaceFirst('..jpg', '.jpg');
      final srcSingleFile = File(srcSingle);
      if (await srcSingleFile.exists()) {
           try {
            await srcSingleFile.copy(destPath);
            print('Copied (single dot) to $destPath');
          } catch (e) {
            print('Error copying $srcSingle: $e');
          }
      } else {
        print('Source (single dot) also not found: $srcSingle');
      }
    }
  }
}
