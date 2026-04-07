import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final outDir = Directory('ios_screenshots');
  if (!outDir.existsSync()) {
    outDir.createSync();
  }

  const int targetWidth = 1242;
  const int targetHeight = 2688;

  final dir = Directory.current;
  final entities = dir.listSync();
  final imagePaths = entities
      .whereType<File>()
      .where((file) => file.path.endsWith('.png') && file.path.contains('flutter_'))
      .toList();
      
  imagePaths.sort((a, b) => a.path.compareTo(b.path));

  if (imagePaths.isEmpty) {
    print('No flutter_*.png files found.');
    return;
  }

  print('Found ${imagePaths.length} screenshots. Processing first 10...');
  
  // process the first 10 flutter_XX.png files
  for (var file in imagePaths.take(10)) {
    print('Processing ${file.path}...');
    final imageBytes = file.readAsBytesSync();
    final originalImage = img.decodeImage(imageBytes);
    
    if (originalImage == null) {
      print('Could not read image ${file.path}');
      continue;
    }
    
    // Create new image with black background
    final newImage = img.Image(width: targetWidth, height: targetHeight, numChannels: 3);
    for (var p in newImage) {
      p.r = 0; p.g = 0; p.b = 0;
    }
    
    final double imgRatio = originalImage.width / originalImage.height;
    final double targetRatio = targetWidth / targetHeight;
    
    int newW = targetWidth;
    int newH = targetHeight;
    
    if (imgRatio > targetRatio) {
      // image is wider
      newW = targetWidth;
      newH = (newW / imgRatio).round();
    } else {
      // image is taller
      newH = targetHeight;
      newW = (newH * imgRatio).round();
    }
    
    final resizedImage = img.copyResize(originalImage, width: newW, height: newH, interpolation: img.Interpolation.linear);
    
    final int dstX = (targetWidth - newW) ~/ 2;
    final int dstY = (targetHeight - newH) ~/ 2;
    
    img.compositeImage(newImage, resizedImage, dstX: dstX, dstY: dstY);
    
    final outPath = '${outDir.path}/${file.uri.pathSegments.last}';
    final outFile = File(outPath);
    outFile.writeAsBytesSync(img.encodePng(newImage));
    print('Saved $outPath');
  }
}
