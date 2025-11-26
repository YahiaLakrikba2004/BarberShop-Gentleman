import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      print('Starting upload to: ${ref.fullPath}');
      
      final bytes = await imageFile.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      
      final uploadTask = ref.putData(bytes, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
      }, onError: (e) {
        print('Upload stream error: $e');
      });

      // Wait for completion
      await uploadTask.whenComplete(() => print('Upload task completed'));

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      print('Download URL retrieved: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('FATAL ERROR in uploadProfileImage: $e');
      throw Exception('Upload failed: $e');
    }
  }
}
