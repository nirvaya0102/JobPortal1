import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _nameKey = 'user_name';
  static const String _roleKey = 'user_role';
  static const String _locationKey = 'user_location';
  static const String _emailKey = 'user_email';

  static Future<void> saveUser({
    required String name,
    required String role,
    String? location,
    String? email,
  }) async {
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _roleKey, value: role);
    if (location != null && location.trim().isNotEmpty) {
      await _storage.write(key: _locationKey, value: location.trim());
    }
    if (email != null && email.trim().isNotEmpty) {
      await _storage.write(key: _emailKey, value: email.trim());
    }
  }

  static Future<String?> getName() => _storage.read(key: _nameKey);
  static Future<String?> getRole() => _storage.read(key: _roleKey);
  static Future<String?> getLocation() => _storage.read(key: _locationKey);
  static Future<String?> getEmail() => _storage.read(key: _emailKey);

  static Future<void> clear() async {
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _locationKey);
    await _storage.delete(key: _emailKey);
  }
}
