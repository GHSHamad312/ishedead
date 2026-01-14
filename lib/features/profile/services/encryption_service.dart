import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

class EncryptionService {
  // In a real app, this key should be user-generated or fetched securely.
  // For MVP, we use a fixed key (NOT SECURE FOR PRODUCTION).
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final _iv = encrypt.IV.fromLength(16);
  final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  String encryptText(String plainText) {
    if (plainText.isEmpty) return '';
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    return _encrypter.decrypt(
      encrypt.Encrypted.fromBase64(encryptedText),
      iv: _iv,
    );
  }
}
