import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKvService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool?> getBool(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    await _storage.write(key: key, value: value ? 'true' : 'false');
  }

  Future<String?> getString(String key) async {
    return _storage.read(key: key);
  }

  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
