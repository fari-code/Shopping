
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class PasswordService {
  static final _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  static Future<String> hashPassword(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final hash = await key.extractBytes();

    // On stocke le sel et le hachage, jamais le mot de passe.
    return '${base64Encode(salt)}:${base64Encode(hash)}';
  }

  static Future<bool> verifyPassword(
      String password,
      String storedValue,
      ) async {
    final parts = storedValue.split(':');

    if (parts.length != 2) return false;

    try {
      final salt = base64Decode(parts[0]);
      final expectedHash = base64Decode(parts[1]);

      final key = await _algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final actualHash = await key.extractBytes();

      if (actualHash.length != expectedHash.length) {
        return false;
      }

      // Comparaison sans arrêt au premier octet différent.
      var difference = 0;
      for (var i = 0; i < actualHash.length; i++) {
        difference |= actualHash[i] ^ expectedHash[i];
      }

      return difference == 0;
    } catch (_) {
      return false;
    }
  }
}
