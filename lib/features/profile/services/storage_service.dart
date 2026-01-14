import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<String> uploadFile(String uid, File file, String folder) async {
    final fileName = path.basename(file.path);
    final destination = 'users/$uid/$folder/$fileName';

    try {
      final ref = _storage.ref(destination);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      // Handle errors
      rethrow;
    }
  }
}
